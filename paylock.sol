pragma solidity >=0.4.16 <0.7.0;

contract Paylock {
    
    enum State { Working , Completed , Done_1 , Delay , Done_2 , Forfeit }
    
    int disc;
    int clock;
    State st;
    address timeAdd;
    
    constructor(address t) public {
        st = State.Working;
        disc = 0;
        clock = 0;
        timeAdd = t;
    }
    
    function tick() public {
        require(msg.sender == timeAdd);
        clock += 1;
    }

    function signal() public {
        require( st == State.Working );
        st = State.Completed;
        disc = 10;
        clock = 0;
    }

    function collect_1_Y() public {
        require( st == State.Completed && clock < 4 );
        st = State.Done_1;
        disc = 10;
    }

    function collect_1_N() external {
        require( st == State.Completed );
        st = State.Delay;
        disc = 5;
        clock = 0;
    }

    function collect_2_Y() external {
        require( st == State.Delay && clock < 4);
        st = State.Done_2;
        disc = 5;
    }

    function collect_2_N() external {
        require( st == State.Delay );
        st = State.Forfeit;
        disc = 0;
    }

}

contract Supplier {
    
    Paylock p;
    Rental r;
    
    enum State { Working , Rented, Returned, Completed }
    
    State public st;
    
    uint256 public b;
    uint256 public br;
    
    constructor(address pp, address rr) public payable{
        p = Paylock(pp);
        st = State.Working;
        r = Rental(rr);
    }
    
    function finish() external {
        require (st == State.Returned);
        p.signal();
        st = State.Completed;
    }
    
    function aquire_resource() public {
        require (st == State.Working);
        r.rent_out_resource.value(1 wei)();
        st = State.Rented;
    }
    
    function return_resource() public{
        require (st == State.Rented);
        r.retrieve_resource();
        st = State.Returned;
        b = address(this).balance;
        br = address(r).balance;
    }
    
    receive() external payable {}
    
    fallback () external payable {}
    
}

contract Rental {
    
    address public resource_owner;
    bool resource_available;
    int deposit;
    
    constructor() public {
        resource_available = true;
    }
    
    function rent_out_resource() payable external {
        require(resource_available == true && msg.value == 1 wei);
        deposit = 1;
        resource_owner = msg.sender;
        resource_available = false;
    }

    function retrieve_resource() external {
        require(resource_available == false && msg.sender == resource_owner);
        (bool success, ) = msg.sender.call.value(1 wei)(abi.encodeWithSignature("myPayableFunction()"));
        require(success, "Function call failed");
        deposit = 0;
        resource_available = true;
    }
    
    
}