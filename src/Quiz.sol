// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Quiz {
    struct Quiz_item {
        uint id;
        string question;
        string answer;
        uint min_bet;
        uint max_bet;
    }

    mapping(uint => mapping(address => uint256)) public bets;
    uint public vault_balance;
    Quiz_item[] public quizzes;

    constructor() {
        Quiz_item memory q;
        q.id = 1;
        q.question = "1+1=?";
        q.answer = "2";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        addQuiz(q);
    }

    // testAddQuizACL()에 Address(1)로 퀴즈를 추가할 경우 vm.expectRevert(); revert가 발생하여야 한다.
    function addQuiz(Quiz_item memory q) public {require(msg.sender != address(1), "Not allowed to add quiz");
        quizzes.push(q);
    }

    function getAnswer(uint quizId) public view returns (string memory) {
        return quizzes[quizId - 1].answer;
    }

    // testGetQuizSecurity()와 testAddQuizGetQuiz()를 만족하기 위해 getQuiz() 호출시 answer를 ""로 숨겨 반환하도록 한다.
    function getQuiz(uint quizId) public view returns (Quiz_item memory) {
        Quiz_item memory q = quizzes[quizId - 1];
        q.answer = "";
        return q;
    }

    //
    function getQuizNum() public view returns (uint) {        
        return quizzes.length;
    }

    //testFailBetToPlayMin(), testFailBetToPlayMax()를 만족하도록
    //Min_bet, Max_bet 미만이거나 초과할 경우 revert가 발생하여야 한다.
    //testMultiBet()을 만족하기 위해 퀴즈별로 bets를 저장하도록 한다.
    function betToPlay(uint quizId) public payable {
        require(msg.value >= quizzes[quizId - 1].min_bet, "Bet is less than min_bet");
        require(msg.value <= quizzes[quizId - 1].max_bet, "Bet is more than max_bet");
        bets[quizId-1][msg.sender] += msg.value;
        vault_balance += msg.value;
    }

    // testSolve1()은 min_bet이후 1번 퀴즈의 답을 1을 넣고 정답일 경우 true를 반환하여 일치하면 통과한다.
    // testSolve2()는 퀴즈를 맞추지 못할 경우 배팅금액이 vault_balance에 추가된다.
    function solveQuiz(uint quizId, string memory ans) public returns (bool) {
        uint amount = bets[quizId-1][msg.sender];
        if (keccak256(abi.encodePacked(ans)) == keccak256(abi.encodePacked(quizzes[quizId - 1].answer))) {
            return true;
        } else {
            vault_balance += amount;
            bets[quizId-1][msg.sender] = 0;
            return false;
        }
    }

    //testClaim()에서 정답을 맞출 경우
    function claim() public {
        uint totalReward = 0;
        for (uint i = 0; i < quizzes.length; i++) {
            uint betAmount = bets[i][msg.sender];
            if (betAmount > 0) {
                totalReward += betAmount *2;
                bets[i][msg.sender] = 0;
                payable(msg.sender).transfer(totalReward);
                break;
            }
        }
    }

    receive() external payable {}
}