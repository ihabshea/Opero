import "./SafeMath.sol";
import "./ERC20.sol";
import "./OwnablePausable.sol";
contract OPToken is ERC20, Pausable {
    using SafeMath for uint256;

    /*
        Token
    */

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    string public name = "Dcourt";
    uint8 public decimals = 18;
    uint256 totalSupply;
    string public symbol = "DCT";

    function getOwner() public view returns(address){
        return owner;
    }
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(frozen[msg.sender] == false);
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        decreaseVote(msg.sender, _value);
        balances[_to] = balances[_to].add(_value);
        increaseVote(_to, _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(frozen[_from] == false);
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        decreaseVote(_from, _value);
        balances[_to] = balances[_to].add(_value);
        increaseVote(_to, _value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /*
        Minting
    */

    address public saleContract;

    function setSaleContract(address _contract) public onlyOwner {
        require(isContract(_contract));
        saleContract = _contract;
    }

    function removeSaleContract() public onlyOwner {
        saleContract = address(0);
    }

    event Mint(address indexed to, uint256 amount);

    function mint(address _to, uint256 _amount) public returns (bool) {
    require(msg.sender == owner || msg.sender == saleContract);
    require(_mint(_to, _amount));
    }

    function _mint(address _to, uint256 _amount) internal returns (bool) {
      totalSupply = totalSupply.add(_amount);
      balances[_to] = balances[_to].add(_amount);
      increaseVote(_to, _amount);
      emit Mint(_to, _amount);
      emit Transfer(address(0), _to, _amount);
      return true;
    }

    /*
        Governance
    */

    mapping (address => uint256) public owners;
    mapping (address => address) public voters;
    event Signal(address _voter, address _owner, uint256 _amount);
    event ElectedOwner(address _owner, uint256 _votes);

    function signal(address _owner) whenNotPaused public {
        require(isContract(_owner));
        require(balances[msg.sender] > 0);
        require(_owner != address(0) && _owner != owner);
        require(voters[msg.sender] != _owner);

        if(voters[msg.sender] != address(0)){
            owners[voters[msg.sender]].sub(balances[msg.sender]);
        }
        owners[_owner] = owners[_owner].add(balances[msg.sender]);
        voters[msg.sender] = _owner;
        emit Signal(msg.sender, _owner, balances[msg.sender]);
        if(owners[_owner] > (totalSupply.div(2))){
            owner = _owner;
            emit ElectedOwner(_owner, owners[_owner]);
        }
    }

    function ownerPercentage(address _owner) public view returns (uint256) {
      if(owners[_owner] == totalSupply) return 100;
      return (owners[_owner].div(totalSupply)).mul(100);
    }

    function decreaseVote(address _voter, uint256 _amount) private {
        if(voters[_voter] != address(0)){
            emit Signal(_voter, voters[_voter], balances[msg.sender]);
            owners[voters[_voter]] = owners[voters[_voter]].sub(_amount);
        }

    }

    function increaseVote(address _voter, uint256 _amount) private {
        if(voters[_voter] != address(0)){
            emit Signal(_voter, voters[_voter], balances[msg.sender]);
            owners[voters[_voter]] = owners[voters[_voter]].add(_amount);
        }

    }

    mapping (address => bool) public frozen;
    mapping (address => uint256) public frozenAmount;
    function freeze(address _account, bool _value) public onlyOwnerContract returns (uint256) {
        frozen[_account] = _value;
        return balances[_account];
    }
    function freezeAmount(address __account, uint256 _amount) public onlyOwnerContract returns(uint256){
        frozenAmount[__account]= frozenAmount[__account].add(_amount);
        balances[__account] = balances[__account].sub(_amount);
        return balances[__account];
    }
    function burn(address _account, uint256 _amount) public onlyOwnerContract returns (uint256) {
        balances[_account] = balances[_account].sub(_amount);
        totalSupply = totalSupply.sub(_amount);
        decreaseVote(_account, _amount);
        emit Transfer(_account, address(0), _amount);
        return balances[_account];
    }

    function burnAll(address _account) public onlyOwnerContract returns(bool){
        decreaseVote(_account, balances[_account]);
        totalSupply = totalSupply.sub(balances[_account]);
        emit Transfer(_account, address(0), balances[_account]);
        balances[_account] = 0;
        return true;
    }



    /*
        Utils
    */

    function recover(bytes32 hash, bytes memory sig) private pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (sig.length != 65) {
          return (address(0));
        }
        assembly {
          r := mload(add(sig, 32))
          s := mload(add(sig, 64))
          v := byte(0, mload(add(sig, 96)))
        }
        if (v < 27) {
          v += 27;
        }
        if (v != 27 && v != 28) {
          return (address(0));
        } else {
          return ecrecover(hash, v, r, s);
        }
    }

        function isContract(address addr) private view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}
