// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;
import {Test} from "forge-std/Test.sol";
import {DeployDSC} from "../../script/DeplyoyDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
import {HelperConfig} from "../../script/Helperconfig.s.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";

import {DecentralisedStableCoin} from "../../src/DecentralisedStableCoin.sol";

contract DSCEngineTest is Test {
    address public USER = makeAddr("user");
    address public LIQUIDATOR = makeAddr("liquidator");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 20 ether;
    uint256 public constant AMOUNT_DSC_TO_MINT = 1000e18;
    uint256 public constant ZERO = 0;
    address public weth;
    int256 public constant CRASHED_ETH_PRICE = 18e8;

    DSCEngine engine;
    DecentralisedStableCoin dsc;
    HelperConfig helperConfig;
    MockV3Aggregator ethUsdPriceFeed;

    function setUp() public {
        DeployDSC deployer = new DeployDSC();
        (dsc, engine, helperConfig) = deployer.run();
        address wethUsdPriceFeed;
        (wethUsdPriceFeed,, weth,,) = helperConfig.activeConfig();
        ethUsdPriceFeed = MockV3Aggregator(wethUsdPriceFeed);
        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }

    function testDeployment() public view {
        assertNotEq(address(engine), address(0));
        assertEq(dsc.owner(), address(engine));
    }

    function testDepositCollateralRevertsWithUnapprovedToken() public {
        ERC20Mock fakeToken = new ERC20Mock("fake", "fake", USER, AMOUNT_COLLATERAL);
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__TokenNotAllowed.selector);
        engine.depositCollateral(address(fakeToken), AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testDepositCollateral() public {
        vm.startPrank(USER);
        // TODO(human): approve engine to spend USER's weth, then call depositCollateral
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        // Hint: ERC20Mock(weth).approve(...) and engine.depositCollateral(...)
        vm.stopPrank();

        // assert that USER's collateral was recorded correctly`
        uint256 collateralDeposited = engine.getCollateralDepositedByUser(USER, weth);
        assertEq(collateralDeposited, AMOUNT_COLLATERAL);
    }

    function testDepositCollateralRevertsIfAmountIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        engine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testMintDsc() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        // TODO(human): mint DSC and assert USER's minted balance is correct
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        engine.mintDsc(AMOUNT_DSC_TO_MINT);
        vm.stopPrank();
        assertEq(dsc.balanceOf(USER), AMOUNT_DSC_TO_MINT);
    }

    function testMintRevertsIfHealthFactorBroken() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL); // deposit dulu!
        vm.expectRevert(
            abi.encodeWithSelector(
                DSCEngine.DSCEngine__BreaksHealthFactor.selector,
                999900009999000099 // kita update nilainya nanti setelah tau exact-nya
            )
        );
        engine.mintDsc(10001e18); // exceed $10k limit
        vm.stopPrank();
    }

    function testMintDscRevertsIfAmountIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        // TODO(human): mint DSC and assert USER's minted balance is correct
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        engine.mintDsc(ZERO);
        vm.stopPrank();
        // assertEq(dsc.balanceOf(USER),AMOUNT_DSC_TO_MINT);
    }

    function testGetAccountInformation() public {
        vm.startPrank(USER); //#1
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        engine.mintDsc(AMOUNT_DSC_TO_MINT);
        vm.stopPrank();
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(USER);
        assertEq(totalDscMinted, AMOUNT_DSC_TO_MINT);
        assertGt(collateralValueInUsd, 0);
    }

    function testRedeemCollateral() public {
        vm.startPrank(USER); //#1
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        engine.redeemCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        uint256 userBalance = ERC20Mock(weth).balanceOf(USER);
        assertEq(userBalance, STARTING_ERC20_BALANCE);
    }

    function testRedeemCollateralIfHealthFactorIsBroken() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        engine.mintDsc(1000e18);
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, 0));
        engine.redeemCollateral(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
    }

    function testBurnDsc() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        engine.mintDsc(AMOUNT_DSC_TO_MINT);
        dsc.approve(address(engine), AMOUNT_DSC_TO_MINT);
        engine.burnDsc(AMOUNT_DSC_TO_MINT);
        vm.stopPrank();
        assertEq(dsc.balanceOf(USER), 0);
    }

    function testBurnDscIfAmountIsZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        engine.mintDsc(AMOUNT_DSC_TO_MINT);
        dsc.approve(address(engine), AMOUNT_DSC_TO_MINT);
        vm.expectRevert(DSCEngine.DSCEngine__NeedsMoreThanZero.selector);
        engine.burnDsc(ZERO);
        vm.stopPrank();
    }

    function testLiquidateRevertsIfHealthFactorIsOk() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        engine.mintDsc(AMOUNT_DSC_TO_MINT);
        vm.stopPrank();

        vm.startPrank(LIQUIDATOR);
        vm.expectRevert(DSCEngine.DSCEngine__HealthFactorOk.selector);
        engine.liquidate(weth, USER, AMOUNT_DSC_TO_MINT, 0);
        vm.stopPrank();
    }

    function testLiquidate() public {
        uint256 debtToCover = 100e18;
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMOUNT_COLLATERAL);
        engine.depositCollateral(weth, AMOUNT_COLLATERAL);
        engine.mintDsc(debtToCover);
        vm.stopPrank();

        //drop the weth price
        ethUsdPriceFeed.updateAnswer(CRASHED_ETH_PRICE);
        //setup liqui - give eth-mint dsc // $100, bisa di-cover dengan 10 ETH @ $18
        ERC20Mock(weth).mint(LIQUIDATOR, 50 ether);
        vm.startPrank(LIQUIDATOR);
        ERC20Mock(weth).approve(address(engine), 50 ether);
        engine.depositCollateral(weth, 50 ether);
        engine.mintDsc(debtToCover);
        dsc.approve(address(engine), debtToCover);
        engine.liquidate(weth, USER, debtToCover, 0);
        vm.stopPrank();
    }
}
    