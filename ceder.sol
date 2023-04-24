
// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IHbarToken {
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
}

contract CollateralizedToken {
    uint256 private constant _decimals = 8;
    IHbarToken private _hbar;
    uint256 private _collateralRatio; // expressed in proportion, e.g. a value of 2 means 2:1 collateral
    uint256 private _collateralAmount;
    bool private _passedKyc;
    address private _owner;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Approval(address indexed owner, address indexed spender, uint value);

    constructor(IHbarToken hbar, uint256 collateralRatio) {
        require(collateralRatio >= 1, "Collateral ratio must be at least 1:1");
        _hbar = hbar;
        _collateralRatio = collateralRatio;
        _passedKyc = false;
        _owner = msg.sender;
    }

    function name() public pure returns (string memory) {
        return "Ceder Token";
    }

    function symbol() public pure returns (string memory) {
        return "CDT";
    } 

    function decimals() public pure returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _balances[address(this)];
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function mint(address recipient, uint256 amount) public {
        require(msg.sender == _owner, "Only the contract owner can mint new tokens");
        require(_passedKyc, "KYC checks not passed");
        uint256 collateralRequired = amount * _collateralRatio;
        require(collateralRequired <= _collateralAmount, "Insufficient collateral");
        _collateralAmount -= collateralRequired;
        _balances[recipient] += amount;
        _hbar.mint(address(this), collateralRequired);
    }

    function addCollateral(uint256 amount) public {
        require(msg.sender == address(_hbar), "Only the token can add collateral");
        _collateralAmount += amount;
    }

    function withdrawCollateral(uint256 amount) public {
        require(msg.sender == address(this), "Only the contract can withdraw collateral");
        require(amount <= _collateralAmount, "Insufficient collateral");
        _collateralAmount -= amount;
        _hbar.burn(address(this), amount);
        _passKycIfNeeded();
    }

    function passKyc() public {
        require(msg.sender == address(this), "Only the contract can pass KYC");
        _passedKyc = true;
    }

    function changeOwnership(address newOwner) public {
        require(msg.sender == _owner, "Only the contract owner can change ownership");
        _owner = newOwner;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _passKycIfNeeded() internal {
        if (_collateralAmount == 0 && _balances[address(this)] > 0) {
            _passedKyc = true;
        }
    }
}
