pragma solidity ^ 0.4.24;

contract TicketFactory {
    //Ticket一覧を作成
    address[] public deployedTickets;
    //constructor() ? priceをTicketにわたす
    function createTicket(uint price) public {
        //create new contract that get deployed to blockchain
            //user who is tyring to create new Ticketをmsg.senderとして設定
            //キャンペーン内で作成者をmanagerにするのに必要
        address newTicket = new Ticket(price, msg.sender);
        deployedTickets.push(newTicket);
    }
    //make sure we add a function that returns the entire array of deployedProjects
        //view means no date inside the contract is modified by this function
    function getDeployedTickets() public view returns(address[]) {
        return deployedTickets;
    }
}
contract Ticket {
    struct Request {
        uint value;
        uint periodDay;
        bool complete;
        address buyer;
        uint num;
        uint UidKey;
    }
    //These are all variables or pieces of data that are held in out contracts storage
    //storage is available between functions calls (like a computer's hard drive)
    Request[] public requests; //requestsをどこでも使えるように
    address public manager;
    uint public ticketPrice;
    uint public joinersCount; //how many people has joined in and contributed to this contract
    //type of key => type of values, public, label the variables
    mapping(address => uint) public ticketOfOwner;
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    //contract名と同じfunction!contractをdeploy(create)
    //Factoryで設定したmsg.sender=address createrとする。
    //これをただmsg.senderとするとキャンペーンを作った人がmanagerでなくなってしまう(俺になる)
    constructor(uint price, address creater) public {
        //このfunctionを実行させた（つまりコントラクト作成者）人をmanagerに設定
        manager = creater;
        ticketPrice = price;
    }
    function join(uint _days, uint _num, uint _uidkey) public payable {
        //このfunctionでのvalueがミニマム超えていることが条件
        require(msg.value == ticketPrice);

        Request memory newRequest = Request({
           value: ticketPrice * _num,
           periodDay: now + _days * 1 + 2 days,
           complete: false,
           buyer: msg.sender,
           num: _num,
           UidKey: _uidkey
        });
        ticketOfOwner[msg.sender] = requests.push(newRequest) - 1;
        joinersCount++;
    }

    function withdraw(uint _uidkey) public restricted {
        //request[index]というのをたくさん使うのでこのfunction内での変数を設定
        //Requestを使うこと使うことでspecify we are about to create a variable
        //that is going to refer to a request struct
        uint index = ticketOfOwner[msg.sender];
        Request storage request = requests[index];

        require(request.UidKey == _uidkey);

        //この出金リクエストがcompleteしていないことを確認
        require(!request.complete);
        //defaultはfalse。このfunctionで完了するのでtrueにしておく
        request.complete = true;

        //request(=request[index])のvalue(金額)をmanagerに送金
        manager.transfer(request.value);
    }

    function getRefund() public {
        uint index = ticketOfOwner[msg.sender];
        Request storage request = requests[index];
        require(request.buyer==msg.sender);
        require(block.timestamp >= request.periodDay);
        require(request.buyer == msg.sender);
        msg.sender.transfer(request.value);
        request.complete = true;
    }
    //  uintとかはreturnのなかに対応してる
    function getSummary() public view returns (
      uint, uint, uint, address
      ) {
        return (
          ticketPrice,
          address(this).balance,
          requests.length,
          manager
        );
    }
}
