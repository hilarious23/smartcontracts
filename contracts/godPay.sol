pragma solidity ^ 0.4.24;
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";
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
contract Ticket is Ownable {
    using SafeMath for uint256;
    struct Request {
        uint value;
        bool complete;
        mapping(address => bool) approvals;
        address buyer;
        uint num;
    }
    //These are all variables or pieces of data that are held in out contracts storage
    //storage is available between functions calls (like a computer's hard drive)
    Request[] public requests; //requestsをどこでも使えるように
    address public manager;
    uint public ticketPrice;
    uint public periodDay;
    uint public approversCount; //how many people has joined in and contributed to this contract
    //type of key => type of values, public, label the variables
    mapping(address => bool) public approvers;
    mapping(address => uint) public requestedTime;
    // mapping(Request => address) public ticketToOwner;
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
    function join(uint _days, uint _num) public payable {
        //このfunctionでのvalueがミニマム超えていることが条件
        require(msg.value == ticketPrice);

        Request memory newRequest = Request({
           value: ticketPrice * _num,
           complete: false,
           buyer: msg.sender,
           num: _num
        });
        requests.push(newRequest);
        periodDay = requestedTime[msg.sender].add(_days * 1 minutes);
        //label[key]→valueをdefault(=false)からtrueに設定
        approvers[msg.sender] = true;
        approversCount++;
    }
    function approveRequest(uint index) public {
        Request storage request = requests[index];
        //check if msg.sender has already donated this contract
        //falseならここでfunction exit
        require(request.buyer==msg.sender);
        require(approvers[msg.sender]);
        //voteするのでmsg.senderがvoteしたことに(true)にする
        request.approvals[request.buyer] = true;
    }
    function withdraw(uint index) public restricted {
        //request[index]というのをたくさん使うのでこのfunction内での変数を設定
        //Requestを使うこと使うことでspecify we are about to create a variable
        //that is going to refer to a request struct
        Request storage request = requests[index];

        //approveされていることを確認
        require(request.approvals[request.buyer]);
        //この出金リクエストがcompleteしていないことを確認
        require(!request.complete);
        //defaultはfalse。このfunctionで完了するのでtrueにしておく
        request.complete = true;

        //request(=request[index])のvalue(金額)をmanagerに送金
        manager.transfer(request.value);
    }

    function getRefund(uint index) public {
        require(request.buyer==msg.sender);
        require(block.timestamp >= periodDay);
        require(!request.approvals[msg.sender]);
        Request storage request = requests[index];
        require(request.buyer == msg.sender);
        msg.sender.transfer(request.value);
        request.complete = true;
    }
    //  uintとかはreturnのなかに対応してる
    function getSummary() public view returns (
      uint, uint, uint, uint, address
      ) {
        return (
          ticketPrice,
          address(this).balance,
          requests.length,
          approversCount,
          manager
        );
    }
}
