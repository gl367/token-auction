import 'dapple/test.sol';
import 'erc20/base.sol';
import 'manager.sol';
import 'types.sol';

contract TestableManager is SplittingAuctionManager {
    uint public debug_timestamp;

    function getTime() public constant returns (uint) {
        return debug_timestamp;
    }
    function setTime(uint timestamp) {
        debug_timestamp = timestamp;
    }
    function addTime(uint time) {
        setTime(getTime() + time);
    }
    function getCollectMax(uint auction_id) returns (uint) {
        return _auctions[auction_id].collection_limit;
    }
    function getAuction(uint id) constant
        returns (address, ERC20, ERC20, uint, uint, uint, uint)
    {
        Auction a = _auctions[id];
        return (a.beneficiaries[0], a.selling, a.buying,
                a.sell_amount, a.start_bid, a.min_increase, a.duration);
    }
    function getAuctionlet(uint id) constant
        returns (uint, address, uint, uint)
    {
        Auctionlet a = _auctionlets[id];
        return (a.auction_id, a.last_bidder, a.buy_amount, a.sell_amount);
    }
}

contract AuctionTester is Tester {
    SplittingAuctionFrontendType frontend;
    AuctionDatabaseUser db;
    function bindManager(address manager) {
        frontend = SplittingAuctionFrontendType(manager);
        db = AuctionDatabaseUser(manager);
    }
    function doApprove(address spender, uint value, ERC20 token) {
        token.approve(spender, value);
    }
    function doBid(uint auctionlet_id, uint bid_how_much)
    {
        var (, quantity) = db.getLastBid(auctionlet_id);
        frontend.bid(auctionlet_id, bid_how_much, quantity);
    }
    function doBid(uint auctionlet_id, uint bid_how_much, uint sell_amount)
        returns (uint, uint)
    {
        return frontend.bid(auctionlet_id, bid_how_much, sell_amount);
    }
    function doClaim(uint id) {
        return frontend.claim(id);
    }
}

contract AuctionTest is EventfulAuction, EventfulManager, Test {
    TestableManager manager;
    AuctionTester seller;
    AuctionTester bidder1;
    AuctionTester bidder2;
    AuctionTester beneficiary1;
    AuctionTester beneficiary2;

    ERC20 t1;
    ERC20 t2;

    // use prime numbers to avoid coincidental collisions
    uint constant T1 = 5 ** 12;
    uint constant T2 = 7 ** 10;

    uint constant INFINITY = uint(-1);

    function setUp() {
        manager = new TestableManager();
        manager.setTime(block.timestamp);

        var million = 10 ** 6;

        t1 = new ERC20Base(million * T1);
        t2 = new ERC20Base(million * T2);

        seller = new AuctionTester();
        seller.bindManager(manager);

        t1.transfer(seller, 200 * T1);
        seller.doApprove(manager, 200 * T1, t1);

        bidder1 = new AuctionTester();
        bidder1.bindManager(manager);

        t2.transfer(bidder1, 1000 * T2);
        bidder1.doApprove(manager, 1000 * T2, t2);

        bidder2 = new AuctionTester();
        bidder2.bindManager(manager);

        t2.transfer(bidder2, 1000 * T2);
        bidder2.doApprove(manager, 1000 * T2, t2);

        t1.transfer(this, 1000 * T1);
        t2.transfer(this, 1000 * T2);
        t1.approve(manager, 1000 * T1);
        t2.approve(manager, 1000 * T2);

        beneficiary1 = new AuctionTester();
        beneficiary1.bindManager(manager);
        beneficiary2 = new AuctionTester();
        beneficiary2.bindManager(manager);
    }
}
