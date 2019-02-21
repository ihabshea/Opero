contract OPTInterface {
    function getOwner() public view returns(address);
    mapping (address => uint256) public balances;
    mapping (address => bool) public frozen;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function mint(address _to, uint256 _amount) public returns (bool);
    function freeze(address _account, bool _value) public  returns (uint256);
    function burn(address _account, uint256 _amount) public returns (uint256);
    function burnAll(address _account) public returns(bool);
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
        string github;
    }
    struct freelancer{
        address userAddress;
        string name;
        string email;
        string website;
        string github;
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
    struct counterOffer{
        uint256 projectNum;
        client pclient;
        freelancer pfreelancer;
        uint256 newBudget;
        bool  approved;
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

    struct report{
        uint256 projectNum;
        uint256 taskNum;
        string description;
        bool decision;
    }
    enum projectStatus{
        INIT,
        STARTED,
        FROZEN,
        FINISHED
    }

    /*
        mappings
    */
    mapping (address => client) Clients;
    mapping (address => freelancer) Freelancers;
    mapping (uint256 => project) Projects;
    mapping (uint256 => report) Reports;
    mapping (uint256 => task) Tasks;
    mapping (uint256 => PTOA) TOAs;
    mapping (uint256 => tag) Tags;
    mapping (uint256 => offer) Offers;
    mapping (uint256 => counterOffer) CounterOffers;

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


    // function startProject()


}
