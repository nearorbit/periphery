// SPDX-License-Identifier: MIT

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {Math} from "@openzeppelin/contracts/math/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import {IBasicIssuanceModule} from "./interfaces/IBasicIssuanceModule.sol";
import {IController} from "./interfaces/IController.sol";
import {ISetToken} from "./interfaces/ISetToken.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {PreciseUnitMath} from "./lib/PreciseUnitMath.sol";
import {UniSushiV2Library} from "../../external/contracts/UniSushiV2Library.sol";

contract NavCalculator {
    using Address for address payable;
    using SafeMath for uint256;
    using PreciseUnitMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for ISetToken;

    /* ============ Enums ============ */

    enum Exchange {
        Uniswap,
        Sushiswap,
        None
    }

    /* ============ Constants ============= */

    uint256 private constant MAX_UINT96 = 2**96 - 1;
    uint256 private constant ONE = 1 * 10**18;
    address public constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /* ============ State Variables ============ */

    address public WETH;
    address public DAI;

    IUniswapV2Router02 public uniRouter;
    IUniswapV2Router02 public sushiRouter;

    address public immutable uniFactory;
    address public immutable sushiFactory;

    IController public immutable setController;
    IBasicIssuanceModule public immutable basicIssuanceModule;

    /* ============ Modifiers ============ */

    modifier isSetToken(ISetToken _setToken) {
        require(
            setController.isSet(address(_setToken)),
            "ExchangeIssuance: INVALID SET"
        );
        _;
    }

    /* ============ Constructor ============ */

    constructor(
        address _weth,
        address _dai,
        address _uniFactory,
        IUniswapV2Router02 _uniRouter,
        address _sushiFactory,
        IUniswapV2Router02 _sushiRouter,
        IController _setController,
        IBasicIssuanceModule _basicIssuanceModule
    ) public {
        uniFactory = _uniFactory;
        uniRouter = _uniRouter;

        sushiFactory = _sushiFactory;
        sushiRouter = _sushiRouter;

        setController = _setController;
        basicIssuanceModule = _basicIssuanceModule;

        WETH = _weth;
        DAI = _dai;
    }

    /* ============ Views ============ */

    function getEstimatedNav(ISetToken _setToken)
        external
        view
        isSetToken(_setToken)
        returns (uint256 nav)
    {
        // get components
        address[] memory components = _setToken.getComponents();

        // variables
        uint256 sumEth = 0;
        uint256 priceEth = 0;
        uint256[] memory amountEth = new uint256[](components.length);
        uint256[] memory amountComponents = new uint256[](components.length);
        uint256 sumUsd = 0;

        // get total supply
        uint256 totalSupply = _setToken.totalSupply();

        // get price in ETH per component and multiply by contract balance
        for (uint256 i = 0; i < components.length; i++) {
            amountComponents[i] = IERC20(components[i]).balanceOf(
                address(_setToken)
            );
            (amountEth[i], , ) = _getMaxTokenForExactToken(
                ONE,
                components[i],
                WETH
            );
            sumEth = sumEth.add(
                (amountEth[i].mul(amountComponents[i]).div(10**18))
            );
        }

        // convert to usd
        (priceEth, , ) = _getMaxTokenForExactToken(ONE, WETH, DAI);
        sumUsd = sumEth.mul(priceEth);

        nav = sumUsd.div(totalSupply);
    }

    /* ============ Internal ============ */

    /**
     * Compares the amount of token received for an exact amount of another token across both exchanges,
     * and returns the max amount.
     *
     * @param _amountIn     The amount of input token
     * @param _tokenA       The address of tokenA
     * @param _tokenB       The address of tokenB
     *
     * @return              The max amount of tokens that can be received across both exchanges
     * @return              The Exchange on which maximum amount of token can be received
     * @return              The pair address of the uniswap/sushiswap pool containing _tokenA and _tokenB
     */
    function _getMaxTokenForExactToken(
        uint256 _amountIn,
        address _tokenA,
        address _tokenB
    )
        internal
        view
        returns (
            uint256,
            Exchange,
            address
        )
    {
        if (_tokenA == _tokenB) {
            return (_amountIn, Exchange.None, ETH_ADDRESS);
        }

        uint256 uniTokenOut = 0;
        uint256 sushiTokenOut = 0;

        address uniswapPair = _getPair(uniFactory, _tokenA, _tokenB);
        if (uniswapPair != address(0)) {
            (uint256 reserveIn, uint256 reserveOut) = UniSushiV2Library
                .getReserves(uniswapPair, _tokenA, _tokenB);
            uniTokenOut = UniSushiV2Library.getAmountOut(
                _amountIn,
                reserveIn,
                reserveOut
            );
        }

        address sushiswapPair = _getPair(sushiFactory, _tokenA, _tokenB);
        if (sushiswapPair != address(0)) {
            (uint256 reserveIn, uint256 reserveOut) = UniSushiV2Library
                .getReserves(sushiswapPair, _tokenA, _tokenB);
            sushiTokenOut = UniSushiV2Library.getAmountOut(
                _amountIn,
                reserveIn,
                reserveOut
            );
        }

        // Fails if both the values are 0
        require(
            !(uniTokenOut == 0 && sushiTokenOut == 0),
            "ExchangeIssuance: ILLIQUID_SET_COMPONENT"
        );
        return
            (uniTokenOut >= sushiTokenOut)
                ? (uniTokenOut, Exchange.Uniswap, uniswapPair)
                : (sushiTokenOut, Exchange.Sushiswap, sushiswapPair);
    }

    /**
     * Returns the pair address for on a given DEX.
     *
     * @param _factory   The factory to address
     * @param _tokenA    The address of tokenA
     * @param _tokenB    The address of tokenB
     *
     * @return           The pair address (Note: address(0) is returned by default if the pair is not available on that DEX)
     */
    function _getPair(
        address _factory,
        address _tokenA,
        address _tokenB
    ) internal view returns (address) {
        return IUniswapV2Factory(_factory).getPair(_tokenA, _tokenB);
    }
}
