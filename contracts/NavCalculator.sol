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
    address public constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /* ============ State Variables ============ */

    address public WETH;
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
    }

    /* ============ Views ============ */

    function getEstimatedNav(ISetToken _setToken)
        external
        view
        isSetToken(_setToken)
        returns (uint256 sumEth)
    {
        // get components
        address[] memory components = _setToken.getComponents();

        // variables
        uint256 sumEth = 0;
        uint256[] memory amountEthIn = new uint256[](components.length);
        uint256[] memory amountComponents = new uint256[](components.length);
        uint256 sumUsd = 0;

        // get total supply
        uint256 totalSupply = _setToken.totalSupply();

        // get price in ETH per component
        for (uint256 i = 0; i < components.length; i++) {
            amountComponents[i] = IERC20(components[i]).balanceOf(
                address(_setToken)
            );
            (amountEthIn[i], , ) = _getMinTokenForExactToken(
                amountComponents[i],
                WETH,
                components[i]
            );
            sumEth = sumEth.add(amountEthIn[i]);
        }

        // nav = sumUsd / totalSupply;
    }

    /* ============ Internal ============ */

    /**
     * Compares the amount of token required for an exact amount of another token across both exchanges,
     * and returns the min amount.
     *
     * @param _amountOut    The amount of output token
     * @param _tokenA       The address of tokenA
     * @param _tokenB       The address of tokenB
     *
     * @return              The min amount of tokenA required across both exchanges
     * @return              The Exchange on which minimum amount of tokenA is required
     * @return              The pair address of the uniswap/sushiswap pool containing _tokenA and _tokenB
     */
    function _getMinTokenForExactToken(
        uint256 _amountOut,
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
            return (_amountOut, Exchange.None, ETH_ADDRESS);
        }

        uint256 maxIn = PreciseUnitMath.maxUint256();
        uint256 uniTokenIn = maxIn;
        uint256 sushiTokenIn = maxIn;

        address uniswapPair = _getPair(uniFactory, _tokenA, _tokenB);
        if (uniswapPair != address(0)) {
            (uint256 reserveIn, uint256 reserveOut) = UniSushiV2Library
                .getReserves(uniswapPair, _tokenA, _tokenB);
            // Prevent subtraction overflow by making sure pool reserves are greater than swap amount
            if (reserveOut > _amountOut) {
                uniTokenIn = UniSushiV2Library.getAmountIn(
                    _amountOut,
                    reserveIn,
                    reserveOut
                );
            }
        }

        address sushiswapPair = _getPair(sushiFactory, _tokenA, _tokenB);
        if (sushiswapPair != address(0)) {
            (uint256 reserveIn, uint256 reserveOut) = UniSushiV2Library
                .getReserves(sushiswapPair, _tokenA, _tokenB);
            // Prevent subtraction overflow by making sure pool reserves are greater than swap amount
            if (reserveOut > _amountOut) {
                sushiTokenIn = UniSushiV2Library.getAmountIn(
                    _amountOut,
                    reserveIn,
                    reserveOut
                );
            }
        }

        // Fails if both the values are maxIn
        // require(
        //     !(uniTokenIn == maxIn && sushiTokenIn == maxIn),
        //     "ExchangeIssuance: ILLIQUID_SET_COMPONENT"
        // );
        return
            (uniTokenIn <= sushiTokenIn)
                ? (uniTokenIn, Exchange.Uniswap, uniswapPair)
                : (sushiTokenIn, Exchange.Sushiswap, sushiswapPair);
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
