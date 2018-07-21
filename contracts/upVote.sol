pragma solidity ^ 0.4.17;

import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract ProjectFactory {
    //Project一覧を作成
    address[] public deployedProjects;

    //constructor() ? minimumをProjectにわたす
    function createProject(uint minimum, uint _days) public {
        //create new contract that get deployed to blockchain
            //user who is tyring to create new Projectをmsg.senderとして設定
            //キャンペーン内で作成者をmanagerにするのに必要
        address newProject = new Project(minimum, _days, msg.sender);
        deployedProjects.push(newProject);
    }

    //make sure we add a function that returns the entire array of deployedProjects
        //view means no date inside the contract is modified by this function
    function getDeployedProjects() public view returns(address[]) {
        return deployedProjects;
    }
}

contract Project is Ownable {
    using SafeMath for uint256;
    //structure、タイプを定義。変数(下)の側におく。
    //何を常にkeep trackしておくか
    struct Request {
        //Request has 3 fields
        uint value;
        bool complete; //defaultはfalse(completeしてないよ！という状態)
        uint approvalCount;
        //addressがkey,boolがvalueのmapping
        mapping(address => bool) approvals;
    }

    //These are all variables or pieces of data that are held in out contracts storage
    //storage is available between functions calls (like a computer's hard drive)
    Request[] public requests; //requestsをどこでも使えるように
    address public manager;
    uint public minimumContribution;
    uint public startDay;
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
    constructor(uint minimum, uint _days, address creater) public {
        //このfunctionを実行させた（つまりコントラクト作成者）人をmanagerに設定
        manager = creater;
        //minimumとして入力したものをminimumContributionに設定
        minimumContribution = minimum;
        requestedTime[manager] = block.timestamp;
        startDay = requestedTime[manager].add(_days * 1 minutes);
        Request memory newRequest = Request({
            value: 0,
            complete: false,
            approvalCount: 0
        });
        requests.push(newRequest);
    }

    function projectStart() public restricted {
        require(block.timestamp >= startDay);
        require(requests[0].complete == false);
        manager.transfer(address(this).balance / 4);
        requests[0].complete = true;
    }

    // _divには20%→3,50%→2,80%→1をフロントで渡す
    function createRequest(uint _div) public restricted {
        //1st Request...get ready to create a new variable that will contain a 'Request'(Requestという構造)
        //2nd Request...The variable's name is 'newRequest'
        //3rd Request...Create a new instance(中身) of a Request
        //we create brandnew Request Object,最初の指定が唯一のstorage!→これはmemory
        require(requests[requests.length-1].complete);

        Request memory newRequest = Request({
            // createRequestした時点でのバランス/_divが出金額になる
           value: address(this).balance / _div,
           complete: false,
           approvalCount: 0
           //only have to initialize value type. no need to reference type. mapping is reference type
        });

        requests.push(newRequest);
    }

    function join() public payable {
        //このfunctionでのvalueがミニマム超えていることが条件
        require(msg.value > minimumContribution);
        //Joinは1回のみ。2回目やるとエラーでるので表示する
        require(!approvers[msg.sender]);
        //label[key]→valueをdefault(=false)からtrueに設定
        approvers[msg.sender] = true;
        joinervalue[msg.sender] = msg.value;
        approversCount++;
    }

    function approveRequest(uint index) public {
        //request[index]というのをたくさん使うのでこのfunction内での変数を設定
        //requests[index]はいくつかあるrequestのうちどれなのか指定
        Request storage request = requests[index];

        //check if msg.sender has already donated this contract
        //falseならここでfunction exit
        require(approvers[msg.sender]);
        //check if masg.sender has not voted(appriveRequest) before
        //approvalsというmappingでmsg.senderをkeyにもつ場合true,ないなら（not votedなら)false
        //!があるので!falseならtrueとなって進行する
        require(!request.approvals[msg.sender]);

        //voteするのでmsg.senderがvoteしたことに(true)にする
        request.approvals[msg.sender] = true;
        //approvalCountに1プラス
        request.approvalCount++;
    }

    function withdraw(uint index) public restricted {
        //request[index]というのをたくさん使うのでこのfunction内での変数を設定
        //Requestを使うこと使うことでspecify we are about to create a variable
        //that is going to refer to a request struct
        Request storage request = requests[index];

        //PJ参加者の過半数が承認していることを求める
        require(request.approvalCount > (approversCount / 2));
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
          minimumContribution,
          address(this).balance,
          requests.length,
          approversCount,
          manager
        );
    }
}
