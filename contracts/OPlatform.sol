contract OPTInterface {
    function getOwner() public view returns(address);
    mapping (address => uint256) public balances;
    mapping (address => bool) public frozen;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function mint(address _to, uint256 _amount) public returns (bool);
    function freeze(address _account, bool _value) public  returns (uint256);
    function burn(address _account, uint256 _amount) public returns (uint256);
    function burnAll(address _account) public returns(bool);
    function getTotalSupply() public view returns(uint256);
    function freezeAmount(address __account, uint256 _amount) public returns(uint256);
}
import "./SafeMath.sol";

contract OPlatform{
    using SafeMath for uint256;
    OPTInterface OPToken;
    /*
        Variables
    */

    uint256 round;
    uint256 projectCounter;
    uint256 offerCounter;
    uint256 taskCounter;
    uint256 tagCounter;
    uint256 reportCounter;
    uint256 fileCounter;
    uint256 TOACounter;
    uint256 PrizePool;
    uint256 roundsPerHalving;
    uint256 gracePeriod;
    uint256 freezePeriod;
    uint256 projectCollateral;
    uint256 roundWeight;
    uint256 blocksPerRound;
    uint256 genesisBlock;

    /*
        Structs
    */
    struct client{
        address userAddress;
        string name;
        string website;
        string email;
        string medium;
        string linkedin;
        uint256 client;
        string bio;
        string github;
    }
    struct freelancer{
        address userAddress;
        string name;
        string email;
        string website;
        string github;
        string bio;
        string linkedin;
        string medium;
    }
    struct project{
        uint256 projectNum;
        client pclient;
        freelancer pfreelancer;
        string description;
        uint256 budget;
        string title;
        uint256 time;
        uint256 downPayment;
        bool freelancerPenalty;
        bool clientPenalty;
        projectStatus pstatus;
    }
    struct offer{
        project oproject;
        client pclient;
        freelancer pfreelancer;
        uint256 budget;
        uint256 time;
        bool approved;
    }
    struct PTOA{
        uint256 projectNum;
        string text;
    }
    struct tag{
        uint256 projectNum;
        uint256 taskNum;
        address userAddress;
        string tagName;
    }
    struct task{
        uint256 projectNum;
        uint256 taskNum;
        string taskTitle;
        string description;
        bool approved;
    }
    struct attachedToTask{
        uint256 taskNum;
        client aclient;
        freelancer afreelancer;
        string attachmentLink;
    }
    struct attachedtoProject{
        uint256 projectNum;
        client aclient;
        string attachmentLink;
    }
    struct Witness {
       address addr;
       string name;
    }
    struct Judge{
        address addr;
        string name;
        bool approved;
        uint penalties;
        uint currentPenalties;
    }
    struct basicReport{
      uint256 reportNum;
      address accuser;
      project rProject;
      task rTask;
      address defendant;
      string description;
      uint256 basicPenalty;
      bool decided;
      bool verdict;
      bool isTask;
      Judge reportJudge;
    }
    struct judgeReport{
        uint256 jreportNum;
        address accuser;
        basicReport jreport;
        string description;
        bool verdict;
    }
    enum projectStatus{
        INIT,
        STARTED,
        FROZEN,
        FINISHED
    }

    /*

        Modifiers

    */
     modifier onlyWitness {
      uint wRank = witnessRanks[msg.sender];
      require(wRank > 0 &&  wRank < 22);
      _;
    }
    /*
        mappings
    */
    mapping (address => client) Clients;
    mapping (address => freelancer) Freelancers;
    mapping (uint256 => project) Projects;
    mapping (uint256 => basicReport) Reports;
    mapping (uint256 => judgeReport) judgeReports;
    mapping (uint256 => task) Tasks;
    mapping (uint256 => PTOA) TOAs;
    mapping (uint256 => tag) Tags;
    mapping (uint256 => offer) Offers;
    mapping (uint256 => attachedToTask) attachements;
    mapping (uint256 => attachedtoProject) pattachements;
    uint8 witnessCount;
    uint8 maxWitnesses;

    mapping(address => uint256) public delegates;
    mapping(address => address) public voters;
    mapping (uint => Witness) public witnesses;
    mapping(uint256 => mapping(uint256 => bool)) witnessVote;
    mapping(uint => uint) judgeReportVotes;
    mapping(address => Judge) Judges;
    mapping (address => uint) public witnessRanks;
    mapping (address => uint) public votesForJudge;
    mapping(uint => uint) reportVotes;
    /*
        Events
    */
    event FreelancerRegisteration(address indexed userAddresss, string name_, string email_, string medium_, string github_, string linkedin_, string website_);
    event ClientRegisteration(address indexed userAddresss, string name_, string email_, string medium_, string github_, string linkedin_, string website_);
    event projectCreation(uint256 indexed projectNo, address indexed pclient, string title, string description, uint256  budget, uint256  time);
    event OfferCreation(uint256 indexed projectNo, address indexed clientAddress, address indexed freelancerAddress, uint256 budget, uint256 time, bool accepted);
    event projectStarted(uint256 indexed projectNo, uint256 offerNum, address indexed clientAddress, address indexed freelancerAddress, uint256 budget, uint256 time);
    event projectTOA(uint256 indexed projectNo, uint256 TOANum, string TOAText);
    event projectTag(uint256 indexed projectNo, string tagName);
    event taskTag(uint256 indexed taskNo, string tagName);
    event TaskCreation(uint256 indexed projectNo, address indexed freelancerAddress, string taskTitle, string taskDescription);
    /*
        functions

    */
    constructor(address OPAddress, uint256 gracePeriod_, uint256 collateral) public{
        OPToken = OPTInterface(OPAddress);
        gracePeriod = gracePeriod_;
        projectCollateral = collateral;
    }

    function registerUser(string memory name_, string memory email_, string memory medium_, string memory github_, string memory linkedin_, string memory website_, bool freelancer_) public{
        if(freelancer_){
            freelancer storage newFreelancer = Freelancers[tx.origin];
            newFreelancer.name = name_;
            newFreelancer.email = email_;
            newFreelancer.medium = medium_;
            newFreelancer.website = website_;
            newFreelancer.github = github_;
            newFreelancer.linkedin = linkedin_;
            emit FreelancerRegisteration(tx.origin, name_, email_, medium_, github_, linkedin_, website_);
        }else{
            client storage newClient = Clients[tx.origin];
            newClient.name = name_;
            newClient.email = email_;
            newClient.medium = medium_;
            newClient.website = website_;
            newClient.github = github_;
            newClient.client = 1;
            newClient.linkedin = linkedin_;
            emit ClientRegisteration(tx.origin, name_, email_, medium_, github_, linkedin_, website_);
        }
    }
    function newProject(string memory title, string memory description, uint256  budget, uint256  time) public{
        require((OPToken.balanceOf(tx.origin) >= budget + projectCollateral) && (Clients[tx.origin].client == 1));
        //burn the collateral, later if the client spends the budget before starting the project they get penalized by never getting their collateral back
        OPToken.burn(tx.origin, projectCollateral);
        projectCounter = projectCounter.add(1);
        project storage newProject = Projects[projectCounter];
        newProject.title = title;
        newProject.pclient = Clients[tx.origin];
        newProject.description = description;
        newProject.budget = budget;
        newProject.time = time;
        newProject.pstatus = projectStatus.INIT;
        emit projectCreation(projectCounter, tx.origin, title, description, budget, time);
    }
    function newTOA(uint256 projectNo, string memory TOAText) public{
        require(Projects[projectNo].pclient.userAddress == tx.origin);
        TOACounter = TOACounter.add(1);
        PTOA storage newPTOA = TOAs[TOACounter];
        newPTOA.projectNum = projectNo;
        newPTOA.text = TOAText;
        emit projectTOA(projectNo, TOACounter, TOAText);
    }
    function newTag(uint256 projectNo, string memory tagName) public{
        require(Projects[projectNo].pclient.userAddress == tx.origin);
        tagCounter = tagCounter.add(1);
        tag storage atag = Tags[tagCounter];
        atag.projectNum = projectNo;
        atag.tagName =  tagName;
        emit projectTag(projectNo, tagName);
    }
    function newTask(uint256 projectNo, string memory taskTitle, string memory taskDescription) public{
        require((Projects[projectNo].pclient.userAddress == tx.origin) || (Projects[projectNo].pfreelancer.userAddress == tx.origin));
        taskCounter = taskCounter.add(1);
        task storage newTask = Tasks[taskCounter];
        newTask.projectNum = projectNo;
        newTask.taskNum = taskCounter;
        newTask.taskTitle = taskTitle;
        newTask.description = taskDescription;
        emit TaskCreation(projectNo, Projects[projectNo].pfreelancer.userAddress, taskTitle, taskDescription);
    }
    function newTaskTag(uint256 taskNo, string memory tagName) public{
        require(Projects[Tasks[taskNo].projectNum].pclient.userAddress == tx.origin);
        tagCounter = tagCounter.add(1);
        tag storage atag = Tags[tagCounter];
        atag.taskNum = taskNo;
        atag.tagName =  tagName;
        emit taskTag(taskNo, tagName);
    }
    function submitTask(uint256 taskNo, string memory link) public{
        require(Projects[Tasks[taskNo].projectNum].pfreelancer.userAddress == tx.origin);
        fileCounter = fileCounter.add(1);
        attachedToTask storage newAttachment = attachements[fileCounter];
        newAttachment.taskNum = taskNo;
        newAttachment.afreelancer = Projects[Tasks[taskNo].projectNum].pfreelancer;
        //event
    }
    function approveTask(uint256 taskNo) public{
        require(Projects[Tasks[taskNo].projectNum].pclient.userAddress == tx.origin);
        task storage currentTask = Tasks[taskNo];
        currentTask.approved = true;
        //event
    }
    function uploadAttachment(uint256 taskNo, string memory link) public{
        require(Projects[Tasks[taskNo].projectNum].pclient.userAddress == tx.origin);
        fileCounter = fileCounter.add(1);
        attachedToTask storage newAttachment = attachements[fileCounter];
        newAttachment.taskNum = taskNo;
        newAttachment.aclient = Projects[Tasks[taskNo].projectNum].pclient;
        //event
    }
    function addProjectAttachment(uint256 projectNo, string memory link) public{
        require(Projects[projectNo].pclient.userAddress == tx.origin);
        fileCounter = fileCounter.add(1);
        attachedtoProject storage newAttachment = pattachements[fileCounter];
        newAttachment.projectNum = projectNo;
        newAttachment.aclient = Projects[projectNo].pclient;
        //event
    }
    function newOffer(uint256 projectNo, uint256 budget, uint256 time) public{
        require(Clients[tx.origin].client == 0);
        offerCounter = offerCounter.add(1);
        offer storage newOffer = Offers[offerCounter];
        newOffer.oproject =  Projects[projectNo];
        newOffer.pclient = Projects[projectNo].pclient;
        newOffer.pfreelancer = Freelancers[tx.origin];
        newOffer.budget = budget;
        newOffer.time = time;
        emit OfferCreation(projectNo, Projects[projectNo].pclient.userAddress, tx.origin, budget, time, false);
    }
    function acceptOffer(uint256 offerNo) public{
        require((OPToken.balanceOf(tx.origin) >= Offers[offerNo].budget) && (Clients[tx.origin].client == 1) && (Offers[offerNo].oproject.pclient.userAddress == tx.origin));
        Offers[offerNo].approved = true;
        project storage currentProject = Projects[Offers[offerNo].oproject.projectNum];
        currentProject.pfreelancer = Offers[offerNo].pfreelancer;
        currentProject.budget = Offers[offerNo].budget;
        currentProject.time =  Offers[offerNo].time;
        currentProject.pstatus = projectStatus.STARTED;
        uint256 toBeFrozen = currentProject.budget.sub(currentProject.downPayment);
        OPToken.freezeAmount(currentProject.pclient.userAddress, toBeFrozen);
        OPToken.burn(currentProject.pclient.userAddress, currentProject.downPayment);
        OPToken.mint(currentProject.pfreelancer.userAddress, currentProject.downPayment);
        emit projectStarted(currentProject.projectNum, offerNo, currentProject.pclient.userAddress, currentProject.pfreelancer.userAddress, currentProject.budget, currentProject.time);
    }
     function eligibleForWitness(address _delegate) public view returns (bool) {
       return delegates[_delegate] > delegates[witnesses[witnessCount].addr];
    }
    event Stepdown(address indexed _witness, string _name, uint rank);
    event NewWitness(address indexed _witness, string _name, uint rank);
    function witnessStepdown() public onlyWitness  returns (bool) {
     uint rank = witnessRanks[msg.sender];
     Witness memory thisWitness = witnesses[rank];
     delete witnesses[rank];
     witnessRanks[msg.sender] = 0;
     if(rank == witnessCount) return true; // If this the last rank, skipping the next loop
     for (uint i = rank+1; i < witnessCount+1; i++){ // Move up each witness of a lower rank
         witnessRanks[witnesses[i-1].addr] = witnessRanks[witnesses[i].addr];
         witnesses[i-1] = witnesses[i];
     }

     witnessRanks[witnesses[witnessCount].addr] = 0; // Last witness seat must become available after witness stepdown
     delete witnesses[witnessCount];
     emit Stepdown(msg.sender, thisWitness.name, rank);
     return true;
     }
     function becomeWitness(string memory _name) public returns (bool) {
      uint256 weight = delegates[msg.sender];
      require(weight > 0 && ( witnessRanks[msg.sender] > 21 || witnessRanks[msg.sender] ==0));
      uint rank;
      if(witnessCount == 0 ){
        rank = 1;
      }else{
        for (uint i = witnessCount; i > 0 ; i--){ // iterate on the witnesses from the lowest to highest rank to save as much gas as possible. Loop is bounded by witnessCount
            // if(witnesses[i].addr == msg.sender) break; // if message sender is already this witness, throw
            address witnessAddr = witnesses[i].addr;
           uint256 witnessWeight = delegates[witnessAddr];
            if(witnessWeight == 0 && i != 1) continue; //if there is no delegate at this rank and this is not the highest rank then skip this iteration
            if(witnessWeight > weight) break; // if this witness has a higher weight than message sender, break the loop
          if(i == maxWitnesses){  // if this is the lowest witness rank, remove this delegate from witnesses
               witnessRanks[witnessAddr] = 0;
               delete witnesses[i];
            }else{
                witnesses[i+1] = witnesses[i]; // Move this witness down 1 rank
                witnessRanks[witnesses[i+1].addr] = i;
            }
            rank = i;
        }
      }

      require(rank > 0); // Require that message sender has a rank after the loop
      if(rank > 0 && witnessCount < 21){
        witnessCount +=1;
      }
      witnessRanks[msg.sender] = rank;
      Witness storage newWitness = witnesses[rank];
      newWitness.name = _name;
      newWitness.addr = msg.sender;
      emit NewWitness(msg.sender, _name, rank);
      return true;
    }
    event Delegation(address indexed voter, address indexed delegate, uint256 balance);
    function increaseVote(address _voter, uint256 _amount) internal{
      delegates[voters[_voter]] = delegates[voters[_voter]].add(_amount);
      emit Delegation(_voter, voters[msg.sender], OPToken.balanceOf(msg.sender));
    }
    function decreaseVote(address _voter, uint256 _amount) internal{
      delegates[voters[_voter]] = delegates[voters[_voter]].sub(_amount);
      emit Delegation(_voter, voters[_voter], OPToken.balanceOf(msg.sender));
    }

    function signal(address _delegate) public {
        require(OPToken.balanceOf(msg.sender) > 0);
        require(_delegate != address(0));
        require(voters[msg.sender] != _delegate);
        if(voters[msg.sender] != address(0)){
            delegates[voters[msg.sender]] = delegates[voters[msg.sender]].sub(OPToken.balanceOf(msg.sender));
        }
        delegates[_delegate] = delegates[_delegate].add(OPToken.balanceOf(msg.sender));
        voters[msg.sender] = _delegate;
        emit Delegation(msg.sender, _delegate, OPToken.balanceOf(msg.sender));
    }
    function delegatePercentage(address _delegate) public view returns (uint256) {
       if(delegates[_delegate] == OPToken.getTotalSupply()) return 100;
       return (delegates[_delegate].div(OPToken.getTotalSupply())).mul(100);
    }
    function getRanking(address account) public view returns(uint){
        return witnessRanks[account];
    }
    function nominateForJudge(string memory name) public{
        require(Judges[tx.origin].approved == false);
        Judge storage newJudge = Judges[tx.origin];
        newJudge.name = name;
        newJudge.approved = false;

        //event
    }
    function voteForJudge(address address_) public{
        require(witnessRanks[tx.origin] > 0 && witnessRanks[tx.origin] < witnessCount + 1);
        votesForJudge[address_] = votesForJudge[address_].add(1);
        if(votesForJudge[address_] > witnessCount/2){
            Judge storage currentJudge =Judges[address_];
            currentJudge.approved = true;
            //event
        }
        //event
    }
    function fileBasicReportForProject(uint256 projectNum, string memory description) public{
        require( (Projects[projectNum].pfreelancer.userAddress == tx.origin ) || ((Projects[projectNum].pclient.userAddress == tx.origin )) );
        reportCounter =  reportCounter.add(1);
        basicReport storage bReport = Reports[reportCounter];
        bReport.accuser = tx.origin;
        if(Clients[tx.origin].client == 1){
            bReport.defendant= Projects[projectNum].pfreelancer.userAddress;
        }else{
            bReport.defendant= Projects[projectNum].pclient.userAddress;
        }
        project storage currentProject = Projects[projectNum];
        currentProject.pstatus = projectStatus.FROZEN;
        bReport.description = description;
        bReport.rProject = currentProject;
        //event
    }

    function decideBasicReportForProject(uint256 reportNum, bool decision) public{
        require((Judges[tx.origin].approved == true) && (Reports[reportNum].decided = false));
        basicReport storage bReport = Reports[reportNum];
        bReport.verdict = decision;
        bReport.decided = true;
        bReport.isTask = true;
        bReport.reportJudge = Judges[tx.origin];
        project storage currentProject = Projects[bReport.rProject.projectNum];
        if(decision){
            if(Clients[bReport.defendant].client == 1){
                currentProject.clientPenalty =  true;
            }else{
                currentProject.freelancerPenalty = true;
            }
        }
        //event
    }
     function fileBasicReportForTask(uint256 taskNo, string memory description) public{
       require((Projects[Tasks[taskNo].projectNum].pclient.userAddress == tx.origin) || (Projects[Tasks[taskNo].projectNum].pfreelancer.userAddress == tx.origin) );
        reportCounter =  reportCounter.add(1);
        basicReport storage bReport = Reports[reportCounter];
        bReport.accuser = tx.origin;
        if(Clients[tx.origin].client == 1){
            bReport.defendant= Projects[Tasks[taskNo].projectNum].pfreelancer.userAddress;
        }else{
            bReport.defendant= Projects[Tasks[taskNo].projectNum].pclient.userAddress;
        }
        project storage currentProject = Projects[Tasks[taskNo].projectNum];
        currentProject.pstatus = projectStatus.FROZEN;
        bReport.description = description;
        bReport.rProject = currentProject;
        //event
    }

    function decideBasicReportForTask(uint256 reportNum, bool decision) public{
        require((Judges[tx.origin].approved == true) && (Reports[reportNum].decided = false));
        basicReport storage bReport = Reports[reportNum];
        bReport.verdict = decision;
        bReport.decided = true;
        bReport.reportJudge = Judges[tx.origin];
        project storage currentProject = Projects[Tasks[bReport.rTask.taskNum].projectNum];
        if(decision){
            if(Clients[bReport.defendant].client == 1){
                currentProject.clientPenalty =  true;
            }else{
                currentProject.freelancerPenalty = true;
            }
        }
    }
    function appealReport(uint256 reportNum, string memory description) public{
        require( (Projects[Reports[reportNum].rProject.projectNum].pfreelancer.userAddress == tx.origin ) || ((Projects[Reports[reportNum].rProject.projectNum].pclient.userAddress == tx.origin )) || ((Projects[Reports[reportNum].rTask.projectNum].pclient.userAddress == tx.origin )) || ((Projects[Reports[reportNum].rTask.projectNum].pclient.userAddress == tx.origin )) );
        reportCounter = reportCounter.add(1);
        judgeReport storage jReport = judgeReports[reportCounter];
        jReport.accuser = tx.origin;
        jReport.jreport = Reports[reportNum];
        jReport.description = description;
    }
    function voteOnJudgeReport(uint256 JReportNum) public{
        require(witnessRanks[tx.origin] > 0 && witnessRanks[tx.origin] < witnessCount +1);
        witnessVote[witnessRanks[tx.origin]][JReportNum] = true;
        reportVotes[JReportNum] = reportVotes[JReportNum].add(1);
        basicReport storage br = Reports[JReportNum];
        Judge storage currentJudge = br.reportJudge;

        if(reportVotes[JReportNum] > (witnessCount / 2)){
            currentJudge.penalties = currentJudge.penalties.add(1);
            currentJudge.currentPenalties = currentJudge.currentPenalties.add(1);
            if(Clients[br.accuser].client == 0){
                if(br.isTask){
                     project storage currentProject = Projects[br.rTask.projectNum];
                     currentProject.clientPenalty = false;
                }else{
                    project storage currentProject = Projects[br.rProject.projectNum];
                    currentProject.clientPenalty = false;
                }
            }else{
                if(br.isTask){
                     project storage currentProject = Projects[br.rTask.projectNum];
                     currentProject.freelancerPenalty = false;
                }else{
                    project storage currentProject = Projects[br.rProject.projectNum];
                    currentProject.freelancerPenalty = false;
                }
            }
        }

    }
    function finishProject(uint256 projectNum) public{
        require((Projects[projectNum].pclient.userAddress == tx.origin) && (Projects[projectNum].pstatus == projectStatus.STARTED) );
        project storage currentProject = Projects[projectNum];
        if(currentProject.clientPenalty == false){
            OPToken.mint(currentProject.pclient.userAddress, projectCollateral);
        }
        if(currentProject.freelancerPenalty){
            uint256 fPenalty = (currentProject.budget - currentProject.downPayment.div(10));
            uint256 toBePaid = (currentProject.budget - currentProject.downPayment).add(fPenalty);
            OPToken.mint(currentProject.pfreelancer.userAddress, toBePaid);
            OPToken.mint(currentProject.pclient.userAddress, fPenalty);
        }
        currentProject.pstatus = projectStatus.FINISHED;
        //Logic: pay freelancer and return collateral
    }
    // function decideReport(uint256 _reportNumber){
    //   //require(witnessRanks[msg.sender] > 0 && witnessRanks[msg.sender] < 22);
    //   require((block.number > casePeriod) && (block.number < casePeriod + challengingPeriod));
    //   witnessVote[witnessRanks[msg.sender]][_caseID] = true;
    //   reportVotes[_caseID] = reportVotes[_caseID].add(1);
    //   if(reportVotes[_caseID] > (witnessCount/2)){
    //     cases[_caseID].spam = true;
    //   }
    // }

    event Reported(uint256 _caseID, address reporter);
    function reportCase(uint256 _caseID) public returns(bool reported){

        return true;
    }


    // function startProject()


}
