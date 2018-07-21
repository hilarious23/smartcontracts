pragma solidity ^ 0.4.17;

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
        string description;
        uint value;
        bool complete;
        mapping(address => bool) approvals;
    }

    //These are all variables or pieces of data that are held in out contracts storage
    //storage is available between functions calls (like a computer's hard drive)
    Request[] public requests; //requestsをどこでも使えるように
    address public manager;
    uint public ticketPrice;
    //type of key => type of values, public, label the variables
    mapping(address => bool) public approvers;
    mapping(address => uint) public joinervalue;
    uint public approversCount; //how many people has joined in and contributed to this contract
    mapping(address => uint) public requestedTime;

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
        //minimumとして入力したものをminimumContributionに設定
        ticketPrice = price;
        requestedTime[manager] = block.timestamp;
    }

    function createRequest(string description, uint value) public restricted {

        Request memory newRequest = Request({
           description: description,
           value: value,
           complete: false
           //only have to initialize value type. no need to reference type. mapping is reference type
        });

        requests.push(newRequest);
    }

    function join() public payable {
        //このfunctionでのvalueがミニマム超えていることが条件
        require(msg.value == ticketPrice);
        //Joinは1回のみ。2回目やるとエラーでるので表示する
        require(!approvers[msg.sender]);
        //label[key]→valueをdefault(=false)からtrueに設定
        approvers[msg.sender] = true;
        joinervalue[msg.sender] = msg.value;
        approversCount++;
    }

    function approveRequest(uint index) public {
        Request storage request = requests[index];

        //check if msg.sender has already donated this contract
        //falseならここでfunction exit
        require(approvers[msg.sender]);

        //voteするのでmsg.senderがvoteしたことに(true)にする
        request.approvals[msg.sender] = true;
    }

    function withdraw(uint index) public restricted {
        //request[index]というのをたくさん使うのでこのfunction内での変数を設定
        //Requestを使うこと使うことでspecify we are about to create a variable
        //that is going to refer to a request struct
        Request storage request = requests[index];

        //approveされていることを確認
        require(request.approvals[msg.sender]);

        //この出金リクエストがcompleteしていないことを確認
        require(!request.complete);

        //request(=request[index])のvalue(金額)をmanagerに送金
        manager.transfer(request.value);
        //defaultはfalse。このfunctionで完了するのでtrueにしておく
        request.complete = true;
    }

    //  uintとかはreturnのなかに対応してる
    function getSummary() public view returns (
      uint, uint, uint, uint, address
      ) {
        return (
          ticketPrice,
          this.balance,
          requests.length,
          approversCount,
          manager
        );
    }
}
