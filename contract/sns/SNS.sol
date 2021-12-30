// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


library LibString {


    function lenOfChars(string memory src) internal pure returns (uint){
        uint i = 0;
        uint length = 0;
        bytes memory string_rep = bytes(src);
        //UTF-8 skip word
        while (i < string_rep.length)
        {
            i += utf8CharBytesLength(string_rep, i);
            length++;
        }
        return length;
    }

    function lenOfBytes(string memory src) internal pure returns (uint){
        bytes memory srcb = bytes(src);
        return srcb.length;
    }


    function startWith(string memory src, string memory prefix) internal pure returns (bool){
        bytes memory src_rep = bytes(src);
        bytes memory prefix_rep = bytes(prefix);

        if (src_rep.length < prefix_rep.length) {
            return false;
        }

        uint needleLen = prefix_rep.length;
        for (uint i = 0; i < needleLen; i++) {
            if (src_rep[i] != prefix_rep[i]) return false;
        }

        return true;
    }

    function endWith(string memory src, string memory tail) internal pure returns (bool){
        bytes memory src_rep = bytes(src);
        bytes memory tail_rep = bytes(tail);

        if (src_rep.length < tail_rep.length) {
            return false;
        }
        uint srcLen = src_rep.length;
        uint needleLen = tail_rep.length;
        for (uint i = 0; i < needleLen; i++) {
            if (src_rep[srcLen - needleLen + i] != tail_rep[i]) return false;
        }

        return true;
    }


    function equal(string memory self, string memory other) internal pure returns (bool){
        bytes memory self_rep = bytes(self);
        bytes memory other_rep = bytes(other);

        if (self_rep.length != other_rep.length) {
            return false;
        }
        uint selfLen = self_rep.length;
        for (uint i = 0; i < selfLen; i++) {
            if (self_rep[i] != other_rep[i]) return false;
        }
        return true;
    }

    function equalNocase(string memory self, string memory other) internal pure returns (bool){
        return compareNocase(self, other) == 0;
    }

    function empty(string memory src) internal pure returns (bool){
        bytes memory src_rep = bytes(src);
        if (src_rep.length == 0) return true;

        for (uint i = 0; i < src_rep.length; i++) {
            bytes1 b = src_rep[i];
            if (b != 0x20 && b != bytes1(0x09) && b != bytes1(0x0A) && b != bytes1(0x0D)) return false;
        }

        return true;
    }

    function concat(string memory self, string memory str) internal returns (string memory _ret)  {
        _ret = new string(bytes(self).length + bytes(str).length);

        uint selfptr;
        uint strptr;
        uint retptr;
        assembly {
            selfptr := add(self, 0x20)
            strptr := add(str, 0x20)
            retptr := add(_ret, 0x20)
        }

        memcpy(retptr, selfptr, bytes(self).length);
        memcpy(retptr + bytes(self).length, strptr, bytes(str).length);
    }

    //start is char index, not byte index
    function substrByCharIndex(string memory self, uint start, uint len) internal returns (string memory) {
        if (len == 0) return "";
        //start - bytePos
        //len - byteLen
        uint bytePos = 0;
        uint byteLen = 0;
        uint i = 0;
        uint chars = 0;
        bytes memory self_rep = bytes(self);
        bool startMet = false;
        //UTF-8 skip word
        while (i < self_rep.length)
        {
            if (chars == start) {
                bytePos = i;
                startMet = true;
            }
            if (chars == (start + len)) {
                byteLen = i - bytePos;
            }
            i += utf8CharBytesLength(self_rep, i);
            chars++;
        }
        if (chars == (start + len)) {
            byteLen = i - bytePos;
        }
        require(startMet, "start index out of range");
        require(byteLen != 0, "len out of range");

        string memory ret = new string(byteLen);

        uint selfptr;
        uint retptr;
        assembly {
            selfptr := add(self, 0x20)
            retptr := add(ret, 0x20)
        }

        memcpy(retptr, selfptr + bytePos, byteLen);
        return ret;
    }

    function compare(string memory self, string memory other) internal pure returns (int8){
        bytes memory selfb = bytes(self);
        bytes memory otherb = bytes(other);
        //byte by byte
        for (uint i = 0; i < selfb.length && i < otherb.length; i++) {
            bytes1 b1 = selfb[i];
            bytes1 b2 = otherb[i];
            if (b1 > b2) return 1;
            if (b1 < b2) return - 1;
        }
        //and length
        if (selfb.length > otherb.length) return 1;
        if (selfb.length < otherb.length) return - 1;
        return 0;
    }

    function compareNocase(string memory self, string memory other) internal pure returns (int8){
        bytes memory selfb = bytes(self);
        bytes memory otherb = bytes(other);
        for (uint i = 0; i < selfb.length && i < otherb.length; i++) {
            bytes1 b1 = selfb[i];
            bytes1 b2 = otherb[i];
            bytes1 ch1 = b1 | 0x20;
            bytes1 ch2 = b2 | 0x20;
            if (ch1 >= 'a' && ch1 <= 'z' && ch2 >= 'a' && ch2 <= 'z') {
                if (ch1 > ch2) return 1;
                if (ch1 < ch2) return - 1;
            }
            else {
                if (b1 > b2) return 1;
                if (b1 < b2) return - 1;
            }
        }

        if (selfb.length > otherb.length) return 1;
        if (selfb.length < otherb.length) return - 1;
        return 0;
    }

    function toUppercase(string memory src) internal pure returns (string memory){
        bytes memory srcb = bytes(src);
        for (uint i = 0; i < srcb.length; i++) {
            bytes1 b = srcb[i];
            if (b >= 'a' && b <= 'z') {
                b &= bytes1(0xDF);
                // -32
                srcb[i] = b;
            }
        }
        return src;
    }

    function toLowercase(string memory src) internal pure returns (string memory){
        bytes memory srcb = bytes(src);
        for (uint i = 0; i < srcb.length; i++) {
            bytes1 b = srcb[i];
            if (b >= 'A' && b <= 'Z') {
                b |= 0x20;
                srcb[i] = b;
            }
        }
        return src;
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string
     * 
     * @param src When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param value The needle to search for, at present this is currently
     *               limited to one character
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(string memory src, string memory value)
    internal
    pure
    returns (int) {
        return indexOf(src, value, 0);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     * 
     * @param src When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param value The needle to search for, at present this is currently
     *               limited to one character
     * @param offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(string  memory src, string memory value, uint offset)
    internal
    pure
    returns (int) {
        bytes memory srcBytes = bytes(src);
        bytes memory valueBytes = bytes(value);

        assert(valueBytes.length == 1);

        for (uint i = offset; i < srcBytes.length; i++) {
            if (srcBytes[i] == valueBytes[0]) {
                return int(i);
            }
        }

        return - 1;
    }

    function split(string memory src, string memory separator)
    internal
    pure
    returns (string[] memory splitArr) {
        bytes memory srcBytes = bytes(src);

        uint offset = 0;
        uint splitsCount = 1;
        int limit = - 1;
        while (offset < srcBytes.length - 1) {
            limit = indexOf(src, separator, offset);
            if (limit == - 1)
                break;
            else {
                splitsCount++;
                offset = uint(limit) + 1;
            }
        }

        splitArr = new string[](splitsCount);

        offset = 0;
        splitsCount = 0;
        while (offset < srcBytes.length - 1) {

            limit = indexOf(src, separator, offset);
            if (limit == - 1) {
                limit = int(srcBytes.length);
            }

            string memory tmp = new string(uint(limit) - offset);
            bytes memory tmpBytes = bytes(tmp);

            uint j = 0;
            for (uint i = offset; i < uint(limit); i++) {
                tmpBytes[j++] = srcBytes[i];
            }
            offset = uint(limit) + 1;
            splitArr[splitsCount++] = string(tmpBytes);
        }
        return splitArr;
    }

    //------------HELPER FUNCTIONS----------------

    function utf8CharBytesLength(bytes memory stringRep, uint ptr) internal pure returns (uint){

        if ((stringRep[ptr] >> 7) == bytes1(0))
            return 1;
        if ((stringRep[ptr] >> 5) == bytes1(0x06))
            return 2;
        if ((stringRep[ptr] >> 4) == bytes1(0x0e))
            return 3;
        if ((stringRep[ptr] >> 3) == bytes1(0x1e))
            return 4;
        return 1;
    }

    function memcpy(uint dest, uint src, uint len) internal view {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

}

//----------------------------LinkKey----------------------------------

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library Timers {
    struct Timestamp {
        uint64 _deadline;
    }

    function getDeadline(Timestamp memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(Timestamp storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(Timestamp storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(Timestamp memory timer) internal view returns (bool) {
        return timer._deadline > block.timestamp;
    }

    function isExpired(Timestamp memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.timestamp;
    }

    struct BlockNumber {
        uint64 _deadline;
    }

    function getDeadline(BlockNumber memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(BlockNumber storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(BlockNumber storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(BlockNumber memory timer) internal view returns (bool) {
        return timer._deadline > block.number;
    }

    function isExpired(BlockNumber memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.number;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
    unchecked {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
        _balances[sender] = senderBalance - amount;
    }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
    }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract LinkKey is ERC20, Ownable, Pausable {

    using Timers for Timers.Timestamp;
    using SafeMath for uint256;

    mapping(address => bool) public minter;

    address public userCollectAddress;
    address public teamCollectAddress;
    address public investorCollectAddress;
    address public bidderCollectAddress;

    uint256 public totalShare;
    uint256 public userShare;
    uint256 public teamShare;
    uint256 public investorShare;
    uint256 public bidderShare;

    uint256 public releaseAmount;

    Timers.Timestamp public releaseTime;

    constructor(string memory name_, string memory symbol_,
        uint64 deadline_, address userCollectAddress_,
        address teamCollectAddress_, address investorCollectAddress_, address bidderCollectAddress_,
        uint256 releaseAmount_) ERC20(name_, symbol_) Pausable(){

        releaseTime.setDeadline(deadline_);

        userCollectAddress = userCollectAddress_;
        teamCollectAddress = teamCollectAddress_;
        investorCollectAddress = investorCollectAddress_;
        bidderCollectAddress = bidderCollectAddress_;

        userShare = 5;
        teamShare = 1;
        investorShare = 3;
        bidderShare = 1;
        setTotalShare();

        releaseAmount = releaseAmount_;
    }

    modifier releasing(){
        require(releaseTime.isPending(), "token release stop, permission denied.");
        _;
    }

    modifier releaseStop() {
        require(releaseTime.isExpired(), "token releasing, permission denied.");
        _;
    }

    function mint() public returns (bool){
        if ((!minter[_msgSender()]) || releaseTime.isExpired() || paused() || totalShare <= 0) {
            return false;
        }

        uint256 userCollectToken = releaseAmount.mul(1 ether).mul(userShare).div(totalShare);
        uint256 teamCollectToken = releaseAmount.mul(1 ether).mul(teamShare).div(totalShare);
        uint256 investorCollectToken = releaseAmount.mul(1 ether).mul(investorShare).div(totalShare);
        uint256 bidderCollectToken = releaseAmount.mul(1 ether).mul(bidderShare).div(totalShare);

        _mint(userCollectAddress, userCollectToken);
        _mint(teamCollectAddress, teamCollectToken);
        _mint(investorCollectAddress, investorCollectToken);
        _mint(bidderCollectAddress, bidderCollectToken);
        return true;
    }

    function setTotalShare() internal {
        totalShare = userShare + teamShare + investorShare + bidderShare;
    }

    function setUserShare(uint256 userShare_) public releaseStop onlyOwner {
        userShare = userShare_;
        setTotalShare();
    }

    function setTeamShare(uint256 teamShare_) public releaseStop onlyOwner {
        teamShare = teamShare_;
        setTotalShare();
    }

    function setInvestorShare(uint256 investorShare_) public releaseStop onlyOwner {
        investorShare = investorShare_;
        setTotalShare();
    }

    function setBidderShare(uint256 bidderShare_) public releaseStop onlyOwner {
        bidderShare = bidderShare_;
        setTotalShare();
    }

    function setReleaseTime(uint64 deadline_) public releaseStop onlyOwner {
        releaseTime.setDeadline(deadline_);
    }

    function setUserCollectAddress(address userCollectAddress_) public onlyOwner {
        userCollectAddress = userCollectAddress_;
    }

    function setTeamCollectAddress(address teamCollectAddress_) public onlyOwner {
        teamCollectAddress = teamCollectAddress_;
    }

    function setInvestorCollectAddress(address investorCollectAddress_) public onlyOwner {
        investorCollectAddress = investorCollectAddress_;
    }

    function setBidderCollectAddress(address bidderCollectAddress_) public onlyOwner {
        bidderCollectAddress = bidderCollectAddress_;
    }

    function setMinter(address minter_) public onlyOwner {
        minter[minter_] = true;
    }

    function removeMinter(address minter_) public onlyOwner {
        minter[minter_] = false;
    }

    function burn(uint256 amount_) public whenNotPaused {
        _burn(_msgSender(), amount_);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public whenNotPaused {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
    unchecked {
        _approve(account, _msgSender(), currentAllowance - amount);
    }
        _burn(account, amount);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}

//----------------------------NFT----------------------------------

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value : value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string  _name;

    // Token symbol
    string  _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) public _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // /**
    //  * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
    //  */
    // constructor(string memory name_, string memory symbol_) {
    //     _name = name_;
    //     _symbol = symbol_;
    // }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwner(address owner) external view returns (uint256[] memory tokenIds);
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[])  _ownedTokensArr;


    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
    * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwner(address owner) public view virtual override returns (uint256[] memory) {
        return _ownedTokensArr[owner];
    }


    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
        if (from != address(0)) {
            require(_removeTokenToOwneArr(from, tokenId), "ERC721Enumerable --- _beforeTokenTransfer --- _removeTokenToOwneArr error!!!");
        }
        if (to != address(0)) {
            require(_addTokenToOwneArr(to, tokenId), "ERC721Enumerable --- _beforeTokenTransfer --- _addTokenToOwneArr error!!!");
        }


    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;

    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to add a token to this arr's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwneArr(address to, uint256 tokenId) private returns (bool){
        _ownedTokensArr[to].push(tokenId);
        return true;
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex;
            // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;
        // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex;
        // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev Private function to add a token to this arr's ownership-tracking data structures.
     * @param from address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be deleted to the tokens list of the given address
     */
    function _removeTokenToOwneArr(address from, uint256 tokenId) private returns (bool){
        bool flag;
        uint256[] memory tempArr = _ownedTokensArr[from];
        for (uint256 i = 0; i < tempArr.length - 1; i++) {
            if (tempArr[i] == tokenId) {
                flag = true;
            }
            if (flag) {
                _ownedTokensArr[from][i] = tempArr[i + 1];
            }
        }
        _ownedTokensArr[from].pop();

        return true;
    }
}

abstract contract ERC721URIStorage is ERC721Enumerable {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
        super._burn(tokenId);
    }
}


contract NFT is ERC721URIStorage, Ownable {

    //The number that has been minted
    uint256 private _tokenMinted = 0;

    //In addition to the number cast by the administrator, the other numbers cast
    uint256  _tokenMintedExpManager = 0;


    /**
     * @dev mint and add _tokenMintedExpManager
     */
    function _addrMint() internal returns (uint256){
        uint256 tokenId = _tokenMinted + 1;
        super._safeMint(_msgSender(), tokenId);
        _tokenMinted += 1;
        _tokenMintedExpManager += 1;
        return tokenId;
    }


    /**
     * @dev mint
     * @param tokenURI_ NFT tokenURI
     */
    function _snsMint(string memory tokenURI_, bool isAddTokenMintedExpManager_) internal returns (uint256){
        uint256 tokenId = _tokenMinted + 1;
        super._safeMint(_msgSender(), tokenId);
        _tokenMinted += 1;
        if (isAddTokenMintedExpManager_) {
            _tokenMintedExpManager += 1;
        }
        require(_setSigleTokenURI(tokenId, tokenURI_));
        return tokenId;
    }

    mapping(uint256 => bool) setTokenURLOnce;

    /**
     * @dev mint and add _tokenMintedExpManager
     * @param tokenURI_ NFT tokenURI
     */
    function _setSigleTokenURI(uint256 tokenId_, string memory tokenURI_) public returns (bool){
        require(!setTokenURLOnce[tokenId_], "013 --- NFT.sol --- setTokenURI --- tokenURI has been set!!!");
        super._setTokenURI(tokenId_, tokenURI_);
        setTokenURLOnce[tokenId_] = true;
        return true;
    }

    /**
     * @dev mint and add _tokenMintedExpManager
     * @param tokenIds_ NFT tokenId
     * @param tokenURIs_ NFT tokenURI
     */
    function setTokenURI(uint256[] memory tokenIds_, string[] memory tokenURIs_) external onlyOwner {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            require(_setSigleTokenURI(tokenIds_[i], tokenURIs_[i]));
        }
    }


}

//----------------------------SNS----------------------------------

interface Resolver {

    event ContentChanged(string indexed name_, string type_, string newContent);
    event OwnerChanged(string indexed name_, address newOwner);

    function setRecords(string memory name_, address owner_) external;

    function getEthAddress(string memory name_) external view returns (string memory);

    function getBtcAddress(string memory name_) external view returns (string memory);

    function getLtcAddress(string memory name_) external view returns (string memory);

    function getDogeAddress(string memory name_) external view returns (string memory);

    function getIpfsUrl(string memory name_) external view returns (string memory);

    function getUrl(string memory name_) external view returns (string memory);

    function getEmail(string memory name_) external view returns (string memory);

    function getAvatar(string memory name_) external view returns (string memory);

    function getDescription(string memory name_) external view returns (string memory);

    function getNotice(string memory name_) external view returns (string memory);

    function getKeywords(string memory name_) external view returns (string memory);

    function getComGithub(string memory name_) external view returns (string memory);

    function getComReddit(string memory name_) external view returns (string memory);

    function getComTwitter(string memory name_) external view returns (string memory);

    function getOrgTelegram(string memory name_) external view returns (string memory);

    function getAllProperties(string memory name_) external returns (string memory);

    function setAllProperties(string memory name_, string memory recordsStr_) external;

}

contract SNSResolver is Resolver {
    using LibString for string;

    struct Record {
        address owner;
        //地址
        string ethAddress;
        string btcAddress;
        string ltcAddress;
        string dogeAddress;
        //ipfs
        string ipfsUrl;
        //文件记录
        string url;
        string email;
        string avatar;
        string description;
        string notice;
        string keywords;
        string comGithub;
        string comReddit;
        string comTwitter;
        string orgTelegram;
    }

    mapping(string => Record) private records;

    mapping(string => string) private recordsStr;

    modifier authorised(string memory name) {
        address owner = records[name].owner;
        require(owner == msg.sender);
        _;
    }

    modifier onlySNS(address snsAddress_) {
        require(snsAddress_ == _snsAddress);
        _;
    }

    address private _snsAddress;



    /**
     * @dev Constructs a new SNS.
     */
    constructor(address snsAddress_) public {
        _snsAddress = snsAddress_;
    }


    function setRecords(string memory name_, address owner_) public onlySNS(msg.sender) {
        records[name_].owner = owner_;
        emit OwnerChanged(name_, owner_);
    }

    function getEthAddress(string memory name_) external view returns (string memory) {
        return records[name_].ethAddress;
    }

    function getBtcAddress(string memory name_) external view returns (string memory){
        return records[name_].btcAddress;
    }

    function getLtcAddress(string memory name_) external view returns (string memory){
        return records[name_].ltcAddress;
    }

    function getDogeAddress(string memory name_) external view returns (string memory){
        return records[name_].dogeAddress;
    }

    function getIpfsUrl(string memory name_) external view returns (string memory){
        return records[name_].ipfsUrl;
    }

    function getUrl(string memory name_) external view returns (string memory){
        return records[name_].url;
    }

    function getEmail(string memory name_) external view returns (string memory){
        return records[name_].email;
    }

    function getAvatar(string memory name_) external view returns (string memory){
        return records[name_].avatar;
    }

    function getDescription(string memory name_) external view returns (string memory){
        return records[name_].description;
    }

    function getNotice(string memory name_) external view returns (string memory){
        return records[name_].notice;
    }

    function getKeywords(string memory name_) external view returns (string memory){
        return records[name_].keywords;
    }

    function getComGithub(string memory name_) external view returns (string memory){
        return records[name_].comGithub;
    }

    function getComReddit(string memory name_) external view returns (string memory){
        return records[name_].comReddit;
    }

    function getComTwitter(string memory name_) external view returns (string memory){
        return records[name_].comTwitter;
    }

    function getOrgTelegram(string memory name_) external view returns (string memory){
        return records[name_].orgTelegram;
    }

    function setAllProperties(string memory name_, string memory recordsStr_) external authorised(name_) {
        recordsStr[name_] = recordsStr_;
        string[] memory properties = recordsStr_.split("-");
        require(properties.length == 15, "SNS.sol --- setAllProperties --- recordsStr error!!!");
        records[name_].ethAddress = properties[0];
        records[name_].btcAddress = properties[1];
        records[name_].ltcAddress = properties[2];
        records[name_].dogeAddress = properties[3];
        records[name_].ipfsUrl = properties[4];
        records[name_].url = properties[5];
        records[name_].email = properties[6];
        records[name_].avatar = properties[7];
        records[name_].description = properties[8];
        records[name_].notice = properties[9];
        records[name_].keywords = properties[10];
        records[name_].comGithub = properties[11];
        records[name_].comReddit = properties[12];
        records[name_].comTwitter = properties[13];
        records[name_].orgTelegram = properties[14];

        emit ContentChanged(name_, "all", recordsStr_);
    }

    function getAllProperties(string memory name_) external view returns (string memory){
        return recordsStr[name_];
    }

}

contract SNS is NFT {
    using SafeMath for uint256;
    using LibString for string;

    //ERC20 key address
    LinkKey  _key;

    //Free casting deadline
    uint256  _freeMintEndTime;

    //Free casting quantity
    uint256  _freeMintQuantity;

    //Whitelist
    mapping(address => bool) _whitelist;

    string END_STR = ".key";

    //Whitelist permissions
    modifier whitelisted(address addr_) {
        require(_whitelist[addr_], "SNS.sol ---whitelisted--- addr_ is not in _whitelist!!!");
        _;
    }

    struct ResolverInfo {
        address resolverAddress;
        address owner;
    }

    //User resolver address
    mapping(string => ResolverInfo)  _resolverInfo;

    //default resolver address
    address  _defaultResolverAddress;

    //SNS of the owner address
    mapping(address => string)  _nameOfOwner;

    //SNS of the tokenId
    mapping(uint256 => string)  _nameOfTokenId;

    //tokenId of the SNS
    mapping(string => uint256)  _tokenIdOfName;

    //Whether the address has been registered
    mapping(address => bool)  _registered;

    //Whether the name has been registered
    mapping(string => bool)  _nameRegistered;

    event Mint(address sender_, string name_, uint256 indexed tokenId);

    event ManagerMint(address sender_, string name_, string tokenURI_, address to_, uint256 indexed tokenId);

    event SetResolverInfo(address sender_, string name_, address resolverAddress_);

    event TransferName(address sender_, address form_, address to_, string name_);

    /**
     * @dev Constructs a new SNS.
     * @param key_ ERC20 address
     * @param name_ NFT name
     * @param symbol_ NFT symbol
     * @param freeMintQuantity_  SNS freeMintQuantity
     */
    constructor(address key_, string memory name_, string memory symbol_, uint256 freeMintQuantity_,uint256 freeMintEndTime_) public {
        //key
        _key = LinkKey(key_);
        //ERC721
        _name = name_;
        _symbol = symbol_;
        //Free casting
        _freeMintQuantity = freeMintQuantity_;
        _freeMintEndTime = freeMintEndTime_;
    }

    /**
     * @dev setDefaultResolverAddress
     * @param defaultResolverAddress_  address
     */
    function setDefaultResolverAddress(address defaultResolverAddress_) external virtual onlyOwner {
        _defaultResolverAddress = defaultResolverAddress_;
    }

    /**
     * @dev setWhitelist
     * @param addrs_ address list
     */
    function setWhitelist(address[] memory addrs_) external virtual onlyOwner {
        for (uint256 i = 0; i < addrs_.length; i ++) {
            _whitelist[addrs_[i]] = true;
        }
    }

    /**
     * @dev The whitelist is open for 3 days registration (free of charge),
     * @param name_ SNS name
     */
    function freeMint(string memory name_) external virtual whitelisted(_msgSender()) {
        require(block.timestamp <= _freeMintEndTime, "001 --- SNS.sol --- freeMint --- over freeMintEndTime!!!");
        require(_tokenMintedExpManager <= _freeMintQuantity, "002 --- SNS.sol --- freeMint --- over freeMintQuantity!!!");
        require(name_.lenOfChars() >= 4, "007 --- SNS.sol --- registerName --- name length is less than 4!!!");
        //NFT
        uint256 tokenId = _addrMint();

        //ENS
        name_ = name_.toLowercase();
        name_ = name_.concat(END_STR);
        require(_registerName(name_, _msgSender()), "003 --- SNS.sol --- freeMint --- Name register fail!!!");
        _nameOfTokenId[tokenId] = name_;
        _tokenIdOfName[name_] = tokenId;
        //Key
        _key.mint();
        emit Mint(_msgSender(), name_, tokenId);
    }

    /**
     * @dev After 1 MATIC/SNS, 10001 starts to charge 10 MATIC/SNS
     * @param name_ SNS name
     */
    function mint(string memory name_) payable external virtual {
        require(name_.lenOfChars() >= 4, "007 --- SNS.sol --- registerName --- name length is less than 4!!!");
        if (_tokenMintedExpManager <= _freeMintQuantity) {
            require(msg.value == 1 ether, "004 --- SNS.sol --- mint --- msg.value should be 1 ether!!!");
        } else {
            require(msg.value == 10 ether, "005 --- SNS.sol --- mint --- msg.value should be 10 ether!!!");
        }
        //Management address to collect money
        payable(owner()).transfer(msg.value);
        //NFT
        uint256 tokenId = _addrMint();
        //ENS
        name_ = name_.toLowercase();
        name_ = name_.concat(END_STR);
        require(_registerName(name_, _msgSender()), "003 --- SNS.sol --- mint --- Name register fail!!!");
        _nameOfTokenId[tokenId] = name_;
        _tokenIdOfName[name_] = tokenId;
        //Key
        _key.mint();
        emit Mint(_msgSender(), name_, tokenId);
    }

    function batchManagerMint(string[] memory names_, string[] memory tokenURIs_, address[] memory tos_) external virtual onlyOwner {
        for (uint256 i = 0; i < names_.length; i++) {
            _managerMint(names_[i], tokenURIs_[i], tos_[i]);
        }
    }

    /**
     * @dev Management address registration, not included in the free quota
     * @param name_ SNS name
     * @param tokenURI_ NFT tokenURI
     * @param to_ SNS owner
     */
    function _managerMint(string memory name_, string memory tokenURI_, address to_) internal virtual onlyOwner {
        //NFT
        uint256 tokenId;
        if (name_.lenOfChars() >= 4) {
            tokenId = _snsMint(tokenURI_, true);
        } else {
            tokenId = _snsMint(tokenURI_, false);
        }

        //ENS
        name_ = name_.toLowercase();
        name_ = name_.concat(END_STR);
        require(_defaultResolverAddress != address(0), "006 --- SNS.sol --- managerMint --- please set defaultResolverAddress!!!");
        require(!_nameRegistered[name_], "003 --- SNS.sol --- managerMint --- name has been registered!!!");
        // require(!_registered[to_],"008 --- SNS.sol --- managerMint --- the address has _registered");
        _resolverInfo[name_].resolverAddress = _defaultResolverAddress;
        _resolverInfo[name_].owner = to_;
        SNSResolver(_defaultResolverAddress).setRecords(name_, to_);
        _nameRegistered[name_] = true;
        _registered[to_] = true;
        _nameOfTokenId[tokenId] = name_;
        _tokenIdOfName[name_] = tokenId;
        //Key
        _key.mint();
        emit ManagerMint(_msgSender(), name_, tokenURI_, to_, tokenId);
    }


    /**
     * @dev registerSNS
     * @param name_ SNS name
     * @param to_ SNS owner
     */
    function _registerName(string memory name_, address to_) internal virtual returns (bool){
        require(_defaultResolverAddress != address(0), "006 --- SNS.sol --- registerName --- please set defaultResolverAddress!!!");
        require(!_nameRegistered[name_], "003 --- SNS.sol --- registerName --- name has been registered!!!");

        // require(!_registered[to_],"008 --- SNS.sol --- registerName --- the address has _registered!!!");
        _nameOfOwner[to_] = name_;
        _resolverInfo[name_].resolverAddress = _defaultResolverAddress;
        _resolverInfo[name_].owner = to_;
        SNSResolver(_defaultResolverAddress).setRecords(name_, to_);
        _nameRegistered[name_] = true;
        _registered[to_] = true;
        return true;
    }

    /**
     * @dev Set resolver information
     * @param name_ SNS name
     * @param resolverAddress_ SNS resolver address
     */
    function setResolverInfo(string memory name_, address resolverAddress_) external virtual {
        require(_resolverInfo[name_].owner == _msgSender(), "009 --- SNS.sol --- setResolverInfo --- onlyOwner can setNewResolverInfo");
        _resolverInfo[name_].resolverAddress = resolverAddress_;
        emit SetResolverInfo(_msgSender(), name_, resolverAddress_);
    }

    /**
     * @dev getResolverAddress
     * @param name_  SNS name
     */
    function getResolverAddress(string memory name_) view external returns (address){
        return _resolverInfo[name_].resolverAddress;
    }

    /**
     * @dev getResolverOwner
     * @param name_  SNS name
     */
    function getResolverOwner(string memory name_) view external returns (address){
        return _resolverInfo[name_].owner;
    }

    /**
     * @dev getSNSName
     * @param addr_  owner address
     */
    function getSNSName(address addr_) view external returns (string memory){
        return _nameOfOwner[addr_];
    }

    /**
    * @dev NFT transfer
     * @param to NFT new owner address
     * @param name_ NFT name_
     */
    function transfer(address to, string memory name_) public virtual {
        //NFT
        super.transferFrom(_msgSender(), to, _tokenIdOfName[name_]);

        //ENS
        require(_transferName(_msgSender(), to, name_), "010 --- SNS.sol --- transferFrom --- transferName fail!!!");
    }

    /**
     * @dev NFT transferFrom
     * @param from NFT owner address
     * @param to NFT new owner address
     * @param tokenId NFT tokenId
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //NFT
        super.transferFrom(from, to, tokenId);
        //ENS
        require(_transferName(from, to, _nameOfTokenId[tokenId]), "010 --- SNS.sol ---transferFrom--- transferName fail!!!");
    }

    /**
     * @dev NFT safeTransferFrom
     * @param from NFT owner address
     * @param to NFT new owner address
     * @param tokenId NFT tokenId
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        //NFT
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev NFT safeTransferFrom
     * @param from NFT owner address
     * @param to NFT new owner address
     * @param tokenId NFT tokenId
     * @param _data NFT extra data
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        //NFT
        super.safeTransferFrom(from, to, tokenId, _data);
        //ENS
        require(_transferName(from, to, _nameOfTokenId[tokenId]), "010 --- SNS.sol ---safeTransferFrom--- transferName fail!!!");
    }

    /**
     * @dev Transfer SNS
     * @param form_ SNS owner address
     * @param to_ SNS new owner address
     * @param name_ SNS name
     */
    function _transferName(address form_, address to_, string memory name_) internal virtual returns (bool){
        require(!_registered[to_], "011 --- SNS.sol ---_transferName--- to_ has a name!!!");
        require(_nameOfOwner[form_].equal(name_), "012 --- SNS.sol ---_transferName--- form_ is not the owner of name!!!");
        _resolverInfo[name_].owner = to_;
        _nameOfOwner[form_] = "";
        _nameOfOwner[to_] = name_;
        _registered[form_] = false;
        _registered[to_] = true;
        SNSResolver(_defaultResolverAddress).setRecords(name_, to_);
        emit TransferName(_msgSender(), form_, to_, name_);
        return true;
    }

    /**
     * @dev is over Free casting deadline?
     */
    function isOverDeadline() public view returns (bool){
        return block.timestamp > _freeMintEndTime;
    }

    /**
     * @dev _tokenMintedExpManager
     */
    function getTokenMintedExpManager() public view returns (uint256){
        return _tokenMintedExpManager;
    }

    /**
     * @dev _tokenMintedExpManager
     */
    function getWhitelist(address addr_) public view returns (bool){
        return _whitelist[addr_];
    }

    /**
     * @dev recordExists
     */
    function recordExists(string memory name_) public view returns (bool){
        return _nameRegistered[name_];
    }

    /**
     * @dev getNameOfOwner
     */
    function getNameOfOwner(address addr_) public view returns (string memory){
        return _nameOfOwner[addr_];
    }

    /**
         * @dev getNameOfOwner
     */
    function getNameOfTokenId(uint256 tokenId_) public view returns (string memory){
        return _nameOfTokenId[tokenId_];
    }


}