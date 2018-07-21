pragma solidity ^ 0.4.17;

contract CampaignFactory {
    //Campaign一覧を作成
    address[] public deployedCampaigns;

    //constructor() ? minimumをCampaignにわたす
    function createCampaign(uint minimum) public {
        //create new contract that get deployed to blockchain
            //user who is tyring to create new Campaignをmsg.senderとして設定
            //キャンペーン内で作成者をmanagerにするのに必要
        address newCampaign = new Campaign(minimum, msg.sender);
        deployedCampaigns.push(newCampaign);
    }

    //make sure we add a function that returns the entire array of deployedCampaigns
        //view means no date inside the contract is modified by this function
    function getDeployedCampaigns() public view returns(address[]) {
        return deployedCampaigns;
    }
}


contract Campaign {
    //structure、タイプを定義。変数(下)の側におく。
    //何を常にkeep trackしておくか
    struct Request {
        //Request has 4 fields
        string description;
        uint value;
        address recipient;//送金先
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
    //type of key => type of values, public, label the variables
    mapping(address => bool) public approvers;
    uint public approversCount; //how many people has joined in and contributed to this contract

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    //contract名と同じfunction!contractをdeploy(create)
    //Factoryで設定したmsg.sender=address createrとする。
    //これをただmsg.senderとするとキャンペーンを作った人がmanagerでなくなってしまう(俺になる)
    constructor(uint minimum, address creater) public {
        //このfunctionを実行させた（つまりコントラクト作成者）人をmanagerに設定
        manager = creater;
        //minimumとして入力したものをminimumContributionに設定
        minimumContribution = minimum;
    }

    function contribute() public payable {
        //このfunctionでのvalueがミニマム超えていることが条件
        require(msg.value > minimumContribution);
        //label[key]→valueをdefault(=false)からtrueに設定
        approvers[msg.sender] = true;
        approversCount++;
    }

    function createRequest(string description, uint value, address recipient)
        public restricted {
            //1st Request...get ready to create a new variable that will contain a 'Request'(Requestという構造)
            //2nd Request...The variable's name is 'newRequest'
            //3rd Request...Create a new instance(中身) of a Request
            //we create brandnew Request Object,最初の指定が唯一のstorage!→これはmemory
            Request memory newRequest = Request({
               description: description,
               value: value,
               recipient: recipient,
               complete: false,
               approvalCount: 0
               //only have to initialize value type. no need to reference type. mapping is reference type
            });

            requests.push(newRequest);
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

    function finalizeRequest(uint index) public restricted {
        //request[index]というのをたくさん使うのでこのfunction内での変数を設定
        //Requestを使うこと使うことでspecify we are about to create a variable
        //that is going to refer to a request struct
        Request storage request = requests[index];

        //PJ参加者の過半数が承認していることを求める
        require(request.approvalCount > (approversCount / 2));
        //この出金リクエストがcompleteしていないことを確認
        require(!request.complete);

        //request(=request[index])のvalue(金額)を予め指定したアドレスに送金
        request.recipient.transfer(request.value);
        //defaultはfalse。このfunctionで完了するのでtrueにしておく
        request.complete = true;
    }

//  uintとかはreturnのなかに対応してる
    function getSummary() public view returns (
      uint, uint, uint, uint, address
      ) {
        return (
          minimumContribution,
          this.balance,
          requests.length,
          approversCount,
          manager
        );
    }

    function getRequestsCount() public view returns (uint) {
        return requests.length;
    }
}
