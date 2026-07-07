// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Ironiun Token (IRN)
 * @notice ERC-20 token — supply fijo, 100,000,000 IRN
 * @dev Desplegado en Polygon POS
 */

// ── Interfaz ERC-20 estándar ──────────────────────────────────────────────────
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// ── Metadata opcional ─────────────────────────────────────────────────────────
interface IERC20Metadata is IERC20 {
    function name()     external view returns (string memory);
    function symbol()   external view returns (string memory);
    function decimals() external view returns (uint8);
}

// ── Contrato principal ────────────────────────────────────────────────────────
contract Ironiun is IERC20, IERC20Metadata {

    // ── Metadata ──────────────────────────────────────────────────────────────
    string  private constant _NAME     = "Ironiun";
    string  private constant _SYMBOL   = "IRN";
    uint8   private constant _DECIMALS = 18;

    // ── Supply fijo: 100,000,000 IRN ──────────────────────────────────────────
    uint256 private constant _TOTAL_SUPPLY = 100_000_000 * 10 ** 18;

    // ── Estado ────────────────────────────────────────────────────────────────
    mapping(address => uint256)                     private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // ── Constructor ───────────────────────────────────────────────────────────
    /**
     * @dev Todos los tokens se acreditan al deployer (el fundador).
     */
    constructor() {
        _balances[msg.sender] = _TOTAL_SUPPLY;
        emit Transfer(address(0), msg.sender, _TOTAL_SUPPLY);
    }

    // ── ERC-20 Metadata ───────────────────────────────────────────────────────
    function name()     external pure override returns (string memory) { return _NAME; }
    function symbol()   external pure override returns (string memory) { return _SYMBOL; }
    function decimals() external pure override returns (uint8)         { return _DECIMALS; }

    // ── ERC-20 Core ───────────────────────────────────────────────────────────
    function totalSupply() external pure override returns (uint256) {
        return _TOTAL_SUPPLY;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        uint256 current = _allowances[from][msg.sender];
        require(current >= amount, "IRN: allowance exceeded");
        unchecked { _allowances[from][msg.sender] = current - amount; }
        emit Approval(from, msg.sender, _allowances[from][msg.sender]);
        _transfer(from, to, amount);
        return true;
    }

    // ── Función de quema (burn) ───────────────────────────────────────────────
    /**
     * @notice Quema tokens propios, reduciendo el supply circulante.
     * @param amount Cantidad en wei (con 18 decimales).
     */
    function burn(uint256 amount) external {
        require(_balances[msg.sender] >= amount, "IRN: burn exceeds balance");
        unchecked { _balances[msg.sender] -= amount; }
        emit Transfer(msg.sender, address(0), amount);
    }

    // ── Internos ──────────────────────────────────────────────────────────────
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "IRN: transfer from zero");
        require(to   != address(0), "IRN: transfer to zero");
        require(_balances[from] >= amount, "IRN: insufficient balance");
        unchecked {
            _balances[from] -= amount;
            _balances[to]   += amount;
        }
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner   != address(0), "IRN: approve from zero");
        require(spender != address(0), "IRN: approve to zero");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}
