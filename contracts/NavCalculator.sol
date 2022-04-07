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

    function getEstimatedNav(ISetToken _setToken)
        external
        view
        isSetToken(_setToken)
        returns (uint256)
    {
        // get components
        address[] memory components = _setToken.getComponents();

        // get total supply

        // get price in ETH per component
    }
}
