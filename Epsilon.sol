/*

EPSILON is an Innovative Upgradeable Smart Token, Governance Controlled and is built upon the idea of Dual Buyback & Burn, Business Level Strong EcoSystem & Anti PumpNDump.
Hence, increasing the investor's value & keeping the investments secure at the same time.
    
Prime Features are:

1) Innovative Upgradeable Smart contract: No need to ever migrate to another contract. Therefore, Future Ready.
2) Governance Controlled: All changes, Minor or Major everything is controlled by the Governance. Therefore, The Holders / Investors.
3) Business Level Strong EcoSystem & Auto LP hold Protocol.
4) Dual Buyback & Burn: Auto (works Automatically) & Manual (When the governance decides to implement it) to keep the price afloat.
5) Anti PumpNDump: Anyone tries to dump gets penalised a JumperFee which is shared to Holders as BNB rewards and covers Buyback.
6) True Anti-Whale: No wallet can hold even a token more than 1% of the total supply.

    
    
    ________     _________       _________     ____    ____            __________      ___          ___
   /$$$$$$$$|   /$$$$$$$$$\     /$$$$$$$$$\    |$$|    |$$|           /$$$$$$$$$$\    |$$$\        |$$|
  |$$$$$$$$/    |$$$$$$$$$$|   |$$$$$$$$$$/    |$$|    |$$|          |$$$$$$$$$$$$|   |$$$$\       |$$|
  |$$|          |$$      $$|   |$$|            |$$|    |$$|          |$$|      |$$|   |$$|$$\      |$$|
  |$$|          |$$      $$|   |$$|            |$$|    |$$|          |$$|      |$$|   |$$|\$$\     |$$|
  |$$|          |$$      $$|   |$$|            |$$|    |$$|          |$$|      |$$|   |$$| \$$\    |$$|
  |$$|_____     |$$______$$|   |$$|_______     |$$|    |$$|          |$$|      |$$|   |$$|  \$$\   |$$|
  |$$$$$$$$|    |$$$$$$$$$$|   |$$$$$$$$$$\    |$$|    |$$|          |$$|      |$$|   |$$|   \$$\  |$$|
  |$$$$$$$$/    |$$$$$$$$$/    |$$$$$$$$$$|    |$$|    |$$|          |$$|      |$$|   |$$|    \$$$ |$$|
  |$$|          |$$|                   |$$|    |$$|    |$$|          |$$|      |$$|   |$$|     \$$\|$$|
  |$$|          |$$|                   |$$|    |$$|    |$$|          |$$|      |$$|   |$$|      \$$$$$|
  |$$|_____     |$$|                   |$$|    |$$|    |$$|_____     |$$|______|$$|   |$$|       \$$$$|
  |$$$$$$$$|    |$$|           /$$$$$$$$$$|    |$$|    |$$$$$$$$$|   |$$$$$$$$$$$$|   |$$|        \$$$|
  |$$$$$$$$/    |$$|           \$$$$$$$$$$|    |$$|    |$$$$$$$$$|    \$$$$$$$$$$/    |$$|         \$$|
                                                                         

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./SafeMath.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./GovernanceControl.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";




interface IEPSTrack {
  function accumulativeDividendOf ( address _owner ) external view returns ( uint256 );
  function allowance ( address owner, address spender ) external view returns ( uint256 );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function balanceOf ( address account ) external view returns ( uint256 );
  function claimWait (  ) external view returns ( uint256 );
  function decimals (  ) external view returns ( uint8 );
  function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
  function distributeDividends (  ) external;
  function dividendOf ( address _owner ) external view returns ( uint256 );
  function excludeFromDividends ( address account ) external;
  function excludedFromDividends ( address ) external view returns ( bool );
  function getAccount ( address _account ) external view returns ( address account, int256 index, int256 iterationsUntilProcessed, uint256 withdrawableDividends, uint256 totalDividends, uint256 lastClaimTime, uint256 nextClaimTime, uint256 secondsUntilAutoClaimAvailable );
  function getAccountAtIndex ( uint256 index ) external view returns ( address, int256, int256, uint256, uint256, uint256, uint256, uint256 );
  function getLastProcessedIndex (  ) external view returns ( uint256 );
  function getNumberOfTokenHolders (  ) external view returns ( uint256 );
  function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
  function lastClaimTimes ( address ) external view returns ( uint256 );
  function lastProcessedIndex (  ) external view returns ( uint256 );
  function minimumTokenBalanceForDividends (  ) external view returns ( uint256 );
  function owner (  ) external view returns ( address );
  function process ( uint256 gas ) external returns ( uint256, uint256, uint256 );
  function processAccount ( address account, bool automatic ) external returns ( bool );
  function temporaryunlock (  ) external;
  function setBalance ( address account, uint256 newBalance ) external;
  function totalDividendsDistributed (  ) external view returns ( uint256 );
  function totalSupply (  ) external view returns ( uint256 );
  function transfer ( address recipient, uint256 amount ) external returns ( bool );
  function transferFrom ( address sender, address recipient, uint256 amount ) external returns ( bool );
  function transferOwnership ( address newOwner ) external;
  function updateClaimWait ( uint256 newClaimWait ) external;
  function withdrawDividend (  ) external pure;
  function withdrawableDividendOf ( address _owner ) external view returns ( uint256 );
  function withdrawnDividendOf ( address _owner ) external view returns ( uint256 );
}




contract Epsilon is ERC20Upgradeable,OwnableUpgradeable {
    using SafeMath for uint256;

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;

    mapping(address => bool) public _isBlacklisted;

    address payable private EcoSystem;
    address payable private Operations;
    bool private swapping;

    struct BuyFee {
        uint16 hodlReward;
        uint16 theBeast;
        uint16 ecoSystem;
        uint16 operations;
        uint16 autoLP;
    }

    struct SellFee {
        uint16 hodlReward;
        uint16 theBeast;
        uint16 ecoSystem;
        uint16 operations;
        uint16 autoLP;
    }

    struct JumperFee {
        uint16 hodlReward;
        uint16 theBeast;
        uint16 ecoSystem;
        uint16 operations;
        uint16 autoLP;
    }

    BuyFee public buyFee;
    SellFee public sellFee;
    JumperFee public jumperFee;

    uint16 public jumperFeeLimit;

    uint16 public internalFee;

    IEPSTrack public dividendTracker;

    uint256 public maxSellTransactionAmount;
    uint256 public maxBuyTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public AntiWhale;
    uint256 public buyBackUpperLimit;

    uint16 private totalBuyFees;
    uint16 private totalSellFees;
    uint16 private totalJumperFees;

    uint256 public PreSalePrice;
    uint256 public ReferralCommission;
    uint16 public PreSaleFee;

    bool public swapEnabled;
    bool public TradingOpen;
    bool public buyBackEnabled;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isExcludedFromLimits;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateDividendTracker(
        address indexed newAddress,
        address indexed oldAddress
    );

    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeFromLimits(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event GasForProcessingUpdated(
        uint256 indexed newValue,
        uint256 indexed oldValue
    );

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SwapETHForTokens(uint256 amountIn, address[] path);

    event SendDividends(uint256 tokensSwapped, uint256 amount);

    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }


    function initialize() public initializer {
        __Ownable_init();
        __ERC20_init("Epsilon", "EPS");
        EcoSystem = payable(0x6520c5eaa0077e3FC826a7AcE3161E6Ae7f984F0);
        Operations = payable(0x26E5e3bE5E28ca3f0030cF2243Fd682CCA794B24);
        jumperFeeLimit = 50; //Jumperfee Limit of balance

        maxSellTransactionAmount = 1000 * 10**6 * (10**9);
        maxBuyTransactionAmount = 1000 * 10**6 * (10**9);
        swapTokensAtAmount = 10 * 10**6 * (10**9);
        AntiWhale = 1000 * 10**6 * (10**9);
        buyBackUpperLimit = 5 ether;

        PreSalePrice = 0.000000333333333 ether;
        ReferralCommission = 5;
        PreSaleFee = 10;

        swapEnabled = false;
        TradingOpen = false;
        buyBackEnabled = true;


        buyFee.hodlReward = 10;
        buyFee.theBeast = 80;
        buyFee.ecoSystem = 40;
        buyFee.operations = 20;
        buyFee.autoLP = 20;
        totalBuyFees =
            buyFee.hodlReward +
            buyFee.theBeast +
            buyFee.ecoSystem +
            buyFee.operations +
            buyFee.autoLP;

        sellFee.hodlReward = 10;
        sellFee.theBeast = 80;
        sellFee.ecoSystem = 40;
        sellFee.operations = 20;
        sellFee.autoLP = 20;
        totalSellFees =
            sellFee.hodlReward +
            sellFee.theBeast +
            sellFee.ecoSystem +
            sellFee.operations +
            sellFee.autoLP;

        jumperFee.hodlReward = 20;
        jumperFee.theBeast = 40;
        jumperFee.ecoSystem = 40;
        jumperFee.operations = 20;
        jumperFee.autoLP = 10;
        totalJumperFees =
            jumperFee.hodlReward +
            jumperFee.theBeast +
            jumperFee.ecoSystem +
            jumperFee.operations +
            jumperFee.autoLP;

        internalFee = 50;


        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x10ED43C718714eb63d5aA57B78B54704E256024E
        );
        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;


       
        // exclude from paying fees or having max transaction amount
        excludeFromFees(address(this), true);
        excludeFromFees(address(0x9f50f89B6EDC132A614a21eEF7296427184eE6A3), true);
        excludeFromFees(Operations, true);
        excludeFromFees(EcoSystem, true);

        excludeFromLimits(address(this), true);
        excludeFromLimits(address(0x9f50f89B6EDC132A614a21eEF7296427184eE6A3), true);
        excludeFromLimits(Operations, true);
        excludeFromLimits(EcoSystem, true);

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 100 * 10**9 * (10**9));
        _approve(address(this), address(uniswapV2Router), ~uint256(0));
    }

    receive() external payable {}

    function transferBeforeSale(
        address referral,
        address recipient,
        uint256 amount
    ) external payable {
        require(TradingOpen == false, "Pre sale has ended");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(
            (amount * PreSalePrice) <= msg.value,
            "Amount of ether is lower than price x quantity"
        );

        uint256 tokenAmount = amount * 10**9;

        require(
            balanceOf(owner()) >= tokenAmount,
            "Balance of owner has been exhausted"
        );
        require(!_isBlacklisted[recipient], " recipient is black listed");

        uint256 fee = tokenAmount.mul(PreSaleFee).div(100);
        uint256 transferrableAmount = tokenAmount - fee;

        super._transfer(owner(), recipient, transferrableAmount);
        super._transfer(
            owner(),
            referral,
            tokenAmount.mul(ReferralCommission).div(100)
        );

        payable(referral).transfer(msg.value.mul(ReferralCommission).div(100));
        payable(owner()).transfer(
            msg.value - msg.value.mul(ReferralCommission).div(100)
        );
    }

    function decimals() public pure override returns (uint8) {
        return 9;
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(
            newAddress != address(dividendTracker),
            "EPS: The dividend tracker already has that address"
        );

        IEPSTrack newDividendTracker = IEPSTrack(payable(newAddress));



        newDividendTracker.excludeFromDividends(address(this));
        newDividendTracker.excludeFromDividends(address(0x9f50f89B6EDC132A614a21eEF7296427184eE6A3));
        newDividendTracker.excludeFromDividends(address(uniswapV2Router));
        newDividendTracker.excludeFromDividends(address(0x000000000000000000000000000000000000dEaD));


        emit UpdateDividendTracker(newAddress, address(dividendTracker));

        dividendTracker = newDividendTracker;
        _setAutomatedMarketMakerPair(uniswapV2Pair, true);

    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "EPS: The router already has that address"
        );
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(
            _isExcludedFromFees[account] != excluded,
            "EPS: Account is already the value of 'excluded'"
        );
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromLimits(address account, bool excluded)
        public onlyOwner {
        _isExcludedFromLimits[account] = excluded;
        emit ExcludeFromLimits(account, excluded);
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }

        emit ExcludeMultipleAccountsFromFees(accounts, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "EPS: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "EPS: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

        if (value) {
            dividendTracker.excludeFromDividends(pair);
        }

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function changeWalletLimit(uint256 _newLimit) external onlyOwner {
        AntiWhale = _newLimit;
    }

    function changeInternalFee(uint16 _newFee) external onlyOwner {
        internalFee = _newFee;
    }

    function changeWallets(
        address payable ecoSystem,
        address payable operations
    ) external onlyOwner {
        EcoSystem = ecoSystem;
        Operations = operations;
    }

    function changePreSalePrice(uint256 _newPrice) external onlyOwner {
        PreSalePrice = _newPrice;
    }

    function getClaimWait() external view returns (uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account)
        public
        view
        returns (uint256)
    {
        return dividendTracker.balanceOf(account);
    }

    function getAccountDividendsInfo(address account)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccount(account);
    }

    function getAccountDividendsInfoAtIndex(uint256 index)
        external
        view
        returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return dividendTracker.getAccountAtIndex(index);
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return dividendTracker.getLastProcessedIndex();
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function OpenTrading(bool value) external onlyOwner {
        TradingOpen = value;
    }

    function setMaxSellTxAMount(uint256 amount) external onlyOwner {
        maxSellTransactionAmount = amount;
    }

    function setMaxBuyTxAMount(uint256 amount) external onlyOwner {
        maxBuyTransactionAmount = amount;
    }

    function setSwapTokensAmt(uint256 amt) external onlyOwner {
        swapTokensAtAmount = amt;
    }

    function setBuyFees(
        uint16 hodlReward,
        uint16 theBeast,
        uint16 ecoSystem,
        uint16 operations,
        uint16 autoLP
    ) external onlyOwner {
        buyFee.hodlReward = hodlReward;
        buyFee.theBeast = theBeast;
        buyFee.ecoSystem = ecoSystem;
        buyFee.operations = operations;
        buyFee.autoLP = autoLP;
        totalBuyFees =
            buyFee.hodlReward +
            buyFee.theBeast +
            buyFee.ecoSystem +
            buyFee.operations +
            buyFee.autoLP;
    }

    function setSellFees(
        uint16 hodlReward,
        uint16 theBeast,
        uint16 ecoSystem,
        uint16 operations,
        uint16 autoLP
    ) external onlyOwner {
        sellFee.hodlReward = hodlReward;
        sellFee.theBeast = theBeast;
        sellFee.ecoSystem = ecoSystem;
        sellFee.operations = operations;
        sellFee.autoLP = autoLP;
        totalSellFees =
            sellFee.hodlReward +
            sellFee.theBeast +
            sellFee.ecoSystem +
            sellFee.operations +
            sellFee.autoLP;
    }

    function setJumperFees(
        uint16 hodlReward,
        uint16 theBeast,
        uint16 ecoSystem,
        uint16 operations,
        uint16 autoLP
    ) external onlyOwner {
        jumperFee.hodlReward = hodlReward;
        jumperFee.theBeast = theBeast;
        jumperFee.ecoSystem = ecoSystem;
        jumperFee.operations = operations;
        jumperFee.autoLP = autoLP;
        totalJumperFees =
            jumperFee.hodlReward +
            jumperFee.theBeast +
            jumperFee.ecoSystem +
            jumperFee.operations +
            jumperFee.autoLP;
    }

    function setBuyBackEnabled(bool _enabled) public onlyOwner {
        buyBackEnabled = _enabled;
    }

    function setJumperFeeLimit(uint16 limit) public onlyOwner {
        jumperFeeLimit = limit;
    }

    function setBuybackUpperLimit(uint256 buyBackLimit) external onlyOwner {
        buyBackUpperLimit = buyBackLimit * 10**15;
    }

    function triggerBuyBack(uint256 amount) external onlyOwner {
        swapETHForTokens(amount);
    }

    function addToBlackList(address[] calldata addresses) external onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            _isBlacklisted[addresses[i]] = true;
        }
    }

    function removeFromBlackList(address account) external onlyOwner {
        _isBlacklisted[account] = false;
    }

    function setSwapEnabled(bool value) external onlyOwner {
        swapEnabled = value;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            !_isBlacklisted[from] && !_isBlacklisted[to],
            "This address is blacklisted"
        );

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (
            !swapping &&
            automatedMarketMakerPairs[to] && // sells only by detecting transfer to automated market maker pair
            from != address(uniswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromLimits[from] //no max for those excluded
        ) {
            require(
                amount <= maxSellTransactionAmount,
                "Sell transfer amount exceeds the maxSell Transaction Amount."
            );
        }

        if (
            !swapping &&
            automatedMarketMakerPairs[from] && // sells only by detecting transfer to automated market maker pair
            from != address(uniswapV2Router) && //router -> pair is removing liquidity which shouldn't have max
            !_isExcludedFromLimits[to] //no max for those excluded
        ) {
            require(
                amount <= maxBuyTransactionAmount,
                "Buy transfer amount exceeds the maxBuy Transaction Amount."
            );
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >=
            swapTokensAtAmount;

        if (
            swapEnabled &&
            !swapping &&
            from != uniswapV2Pair &&
            overMinimumTokenBalance
        ) {
            uint256 balance = address(this).balance;
            if (buyBackEnabled && balance >= 1 ether) {
                if (balance > buyBackUpperLimit) balance = buyBackUpperLimit;

                swapETHForTokens(balance.div(10));
            }

            if (overMinimumTokenBalance) {
                uint256 totalFees = totalBuyFees + totalSellFees;

                uint256 ecoSystem = contractTokenBalance
                    .mul(buyFee.ecoSystem + sellFee.ecoSystem)
                    .div(totalFees);
                swapAndSendToEcoSystem(ecoSystem);

                uint256 theBeast = contractTokenBalance
                    .mul(buyFee.theBeast + sellFee.theBeast)
                    .div(totalFees);
                swapAndSendToTheBeast(theBeast);

                uint256 operations = contractTokenBalance
                    .mul(buyFee.operations + sellFee.operations)
                    .div(totalFees);
                swapAndSendToOperations(operations);

                uint256 liq = contractTokenBalance
                    .mul(buyFee.autoLP + sellFee.autoLP)
                    .div(totalFees);
                swapAndLiquify(liq);

                uint256 hodlReward = contractTokenBalance
                    .mul(buyFee.hodlReward + sellFee.hodlReward)
                    .div(totalFees);
                swapAndSendDividends(hodlReward);
            }
        }

        bool takeFee = true;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            require(TradingOpen, "trading has not yet started");

            uint256 totalFees;

            if (!automatedMarketMakerPairs[to] && !_isExcludedFromLimits[to]) {
                require(
                    balanceOf(to) + amount <= AntiWhale,
                    "you are crossing AntiWhale limit"
                );
            }

            if (automatedMarketMakerPairs[from]) {
                totalFees += totalBuyFees;
            } else if (automatedMarketMakerPairs[to]) {
                totalFees += totalSellFees;

                if (amount >= balanceOf(from).mul(jumperFeeLimit).div(100)) {
                    totalFees += totalJumperFees;
                }
            }

            uint256 fees = amount.mul(totalFees).div(1000);

            if (
                !automatedMarketMakerPairs[from] &&
                !automatedMarketMakerPairs[to] &&
                from != address(uniswapV2Router) &&
                to != address(uniswapV2Router)
            ) {
                uint256 internalFees = amount.mul(internalFee).div(1000);
                super._transfer(from, address(this), internalFees);

                uint256 currentBal = address(this).balance;
                swapTokensForEth(internalFees);
                uint256 finalBal = address(this).balance.sub(currentBal);

                EcoSystem.transfer(finalBal);

                amount = amount.sub(internalFees);
            }

            amount = amount.sub(fees);

            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        try
            dividendTracker.setBalance(payable(from), balanceOf(from))
        {} catch {}
        try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
    }

    function swapAndSendToEcoSystem(uint256 tokens) private {
        uint256 initialBalance = address(this).balance;

        swapTokensForEth(tokens);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        EcoSystem.transfer(newBalance);
    }

    function swapAndSendToTheBeast(uint256 tokens) private {
        swapTokensForEth(tokens);
    }

    function swapAndSendToOperations(uint256 tokens) private {
        uint256 initialBalance = address(this).balance;

        swapTokensForEth(tokens);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        Operations.transfer(newBalance);
    }

    function swapAndSendDividends(uint256 tokens) private {
        uint256 initialBalance = address(this).balance;
        swapTokensForEth(tokens);
        uint256 dividends = address(this).balance.sub(initialBalance);
        (bool success, ) = address(dividendTracker).call{value: dividends}("");

        if (success) {
            emit SendDividends(tokens, dividends);
        }
    }

    function swapAndLiquify(uint256 tokens) private {
        // split the balance into halves
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount)
        private
        lockTheSwap
    {
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapETHForTokens(uint256 amount) private lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(
            0, // accept any amount of Tokens
            path,
            address(0xdead), // Burn address
            block.timestamp.add(300)
        );

        emit SwapETHForTokens(amount, path);
    }
}