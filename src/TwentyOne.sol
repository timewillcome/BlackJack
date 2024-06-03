// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Based} from "./Based.sol";

// when u reach 21 other contestan has 1 shot to draw and if lower than 21 you win

// write custom errors
// at last increase CONTEST_CREATION_PRICE to 1e13

contract TwentyOne is Based {
    Based public based;
    /******************** ERROR ********************/
    /******************** EVENT ********************/
    event ContestCreated(uint256 contestRank);
    event ContestantEntered(uint256 contestRank);
    event ContestantDrawedACard(uint256 contestRank, uint256 drawedCard);
    event ContestantFinishedDrawingCards(
        uint256 contestRank,
        address contestantAddress
    );
    event ContestWinner(uint256 contestRank, address winner);
    /******************** STRUCT ********************/
    struct TwentyOneContest {
        address creator;
        address winner;
        uint256 rank;
        uint256 enterPrice;
        uint256 collectedPrice;
        uint256 durationTime;
        TwentyOneContestant contestant1;
        TwentyOneContestant contestant2;
        bool end;
    }
    TwentyOneContest[] public twentyOneContests;
    struct TwentyOneContestant {
        address contestant;
        uint256 playTime;
        uint256 drawedNumbersSum;
        bool isTurn;
        bool isFinished;
        bool isAceDrawed;
    }
    /******************** RECEIVE ********************/
    receive() external payable {}
    /******************** FALLBACK ********************/
    fallback() external payable {}
    /******************** MAPPING ********************/
    mapping(uint256 contestRank => bool isExist) public isContestExist;
    uint256 increasingNumber = 0;
    mapping(uint256 contestRank => uint256 contestIndex)
        public getContestIndexFromContestRank;
    mapping(address contestantAddress => uint256[] contestRank)
        public enteredContests;
    /******************** MODIFIERs ********************/
    modifier noOne(uint256 _rank) {
        require(
            false,
            "Cant call only callable by itself in certain situations"
        );
        _;
    }
    modifier ifContestExist(uint256 _rank) {
        require(isContestExist[_rank], "Contest isnt exist");
        _;
    }
    modifier isContestEnded(uint256 _rank) {
        uint256 contestIndex = getContestIndexFromContestRank[_rank];
        bytes memory _winner = abi.encodePacked(
            twentyOneContests[contestIndex].winner
        );
        require(
            !twentyOneContests[contestIndex].end ||
                twentyOneContests[contestIndex].durationTime < block.timestamp,
            string(_winner)
        );
        _;
    }
    modifier ifContestant(uint256 _rank) {
        uint256 contestIndex = getContestIndexFromContestRank[_rank];
        require(
            msg.sender == twentyOneContests[_rank].contestant1.contestant ||
                msg.sender == twentyOneContests[_rank].contestant2.contestant,
            "It's not a contestant"
        );
        _;
    }
    modifier ifNotContestant(uint256 _rank) {
        uint256 contestIndex = getContestIndexFromContestRank[_rank];
        require(
            msg.sender !=
                twentyOneContests[contestIndex].contestant1.contestant,
            "Already contestant1"
        );
        require(
            msg.sender !=
                twentyOneContests[contestIndex].contestant2.contestant,
            "Already contestant2"
        );
        _;
    }
    modifier isContestFull(uint256 _rank) {
        uint256 contestIndex = getContestIndexFromContestRank[_rank];
        require(
            twentyOneContests[contestIndex].contestant1.contestant ==
                address(0) ||
                twentyOneContests[contestIndex].contestant2.contestant ==
                address(0),
            "Contest is full"
        );
        _;
    }
    modifier isFinished(uint256 _rank) {
        uint256 contestIndex = getContestIndexFromContestRank[_rank];
        require(
            !twentyOneContests[contestIndex].contestant1.isFinished,
            "Contestant 1 already finished"
        );
        require(
            !twentyOneContests[contestIndex].contestant2.isFinished,
            "Contestant 2 already finished"
        );
        _;
    }
    modifier ifAceDrawed(uint256 _rank) {
        uint256 contestIndex = getContestIndexFromContestRank[_rank];
        require(
            twentyOneContests[contestIndex].contestant1.isAceDrawed ||
                twentyOneContests[contestIndex].contestant2.isAceDrawed,
            "Contestant didnt draw ace"
        );
        _;
    }
    modifier ifNotAceDrawed(uint256 _rank) {
        uint256 contestIndex = getContestIndexFromContestRank[_rank];
        require(
            !twentyOneContests[contestIndex].contestant1.isAceDrawed,
            "Contestant1 draw ace and cant finish before deciding its fate"
        );
        require(
            !twentyOneContests[contestIndex].contestant2.isAceDrawed,
            "Contestant2 draw ace and cant finish before deciding its fate"
        );
        _;
    }
    /******************** FUNCTIONs ********************/
    function createContest(uint256 _enterPrice) public payable {
        // duration time could be top 10 minutes
        // require it before creating it
        // when 10 minutes pass and it doesnt start end contest
        /*************** RANK ***************/
        uint256 contestRank = increasingNumber;
        /*************** REVERT ***************/
        require(
            msg.value == Based.CONTEST_CREATION_PRICE,
            "Invalid contest creation price"
        );
        /*************** STRUCT ****************/
        twentyOneContests.push(
            TwentyOneContest(
                msg.sender,
                address(0),
                contestRank,
                _enterPrice,
                0,
                block.timestamp + 600,
                TwentyOneContestant(
                    address(0),
                    block.timestamp + 10,
                    0,
                    false,
                    false,
                    false
                ),
                TwentyOneContestant(
                    address(0),
                    block.timestamp + 20,
                    0,
                    false,
                    false,
                    false
                ),
                false
            )
        );
        /*************** MAPPING ***************/
        isContestExist[contestRank] = true;
        getContestIndexFromContestRank[contestRank] = increasingNumber;
        increasingNumber++;
        /*************** EVENT ***************/
        emit ContestCreated(contestRank);
        /*************** TRANSFER ***************/
        payable(Based.CONTRACT_OWNER).transfer(msg.value);
    }
    function enterContest(
        uint256 _rank
    )
        public
        payable
        ifContestExist(_rank)
        isContestEnded(_rank)
        isContestFull(_rank)
        ifNotContestant(_rank)
    {
        /*************** CONTEST INDEX ****************/
        uint256 contestIndex = getContestIndexFromContestRank[_rank];
        /*************** REVERT ****************/
        require(
            msg.value == twentyOneContests[contestIndex].enterPrice,
            "Invalid contest entrance price"
        );
        /*************** CONTESTANT1 QUERY ****************/
        if (
            twentyOneContests[contestIndex].contestant1.contestant == address(0)
        ) {
            /*************** CONTESTANT1 STRUCT ****************/
            twentyOneContests[contestIndex].contestant1.contestant = msg.sender;
        }
        /*************** CONTESTANT2 QUERY ****************/
        else {
            /*************** CONTESTANT2 STRUCT ****************/
            twentyOneContests[contestIndex].contestant2.contestant = msg.sender;
            twentyOneContests[contestIndex].contestant1.isTurn = true;
            twentyOneContests[contestIndex].contestant1.playTime =
                block.timestamp +
                30;
            twentyOneContests[contestIndex].durationTime += 600;
        }
        /*************** STRUCT ****************/
        twentyOneContests[contestIndex].collectedPrice += (msg.value * 9) / 10;
        /*************** MAPPING ***************/
        enteredContests[msg.sender].push(_rank);
        /*************** EVENT ***************/
        emit ContestantEntered(_rank);
        /*************** TRANSFER ***************/
        payable(twentyOneContests[contestIndex].creator).transfer(
            (msg.value * 1) / 10
        );
    }
    function drawCard(
        uint256 _rank
    )
        public
        ifContestExist(_rank)
        isContestEnded(_rank)
        ifContestant(_rank)
        isFinished(_rank)
        ifNotAceDrawed(_rank)
    {
        /*************** CONTEST INDEX ****************/
        uint256 contestIndex = getContestIndexFromContestRank[_rank];
        /*************** DRAWING ****************/
        uint256 _drawedNumber = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, blockhash(0), block.number)
            )
        ) % 10;
        /*************** CONTESTANT1 QUERY ****************/
        if (
            msg.sender == twentyOneContests[contestIndex].contestant1.contestant
        ) {
            /*************** CONTESTANT1 REVERT ****************/
            require(
                twentyOneContests[contestIndex].contestant1.isTurn,
                "It's not contestant1's turn"
            );
            if (
                twentyOneContests[contestIndex].contestant1.playTime <
                block.timestamp
            ) {
                twentyOneContests[contestIndex].contestant2.isTurn = true;
                twentyOneContests[contestIndex].contestant1.isTurn = false;
                twentyOneContests[contestIndex].contestant2.playTime =
                    block.timestamp +
                    10;
            }
            /*************** CONTESTANT1 DRAWED NUMBER'S FATE ****************/
            if (_drawedNumber == 1) {
                twentyOneContests[contestIndex].contestant1.isAceDrawed = true;
                twentyOneContests[contestIndex].contestant1.playTime =
                    block.timestamp +
                    30;
            }
            if (_drawedNumber == 0) _drawedNumber = 10;
            /*************** CONTESTANT1 STRUCT ****************/
            twentyOneContests[contestIndex].contestant2.isTurn = true;
            twentyOneContests[contestIndex].contestant1.isTurn = false;
            twentyOneContests[contestIndex]
                .contestant1
                .drawedNumbersSum += _drawedNumber;
        }
        /*************** CONTESTANT1 QUERY ****************/
        else {
            /*************** CONTESTANT1 REVERT ****************/
            require(
                twentyOneContests[contestIndex].contestant2.isTurn,
                "InvalidContestant2Turn"
            );
            if (
                twentyOneContests[contestIndex].contestant2.playTime <
                block.timestamp
            ) {
                twentyOneContests[contestIndex].contestant1.isTurn = true;
                twentyOneContests[contestIndex].contestant2.isTurn = false;
                twentyOneContests[contestIndex].contestant1.playTime =
                    block.timestamp +
                    10;
            }
            /*************** CONTESTANT1 DRAWED NUMBER'S FATE ****************/
            if (_drawedNumber == 1) {
                twentyOneContests[contestIndex].contestant2.isAceDrawed = true;
                twentyOneContests[contestIndex].contestant2.playTime +=
                    block.timestamp +
                    30;
            }
            if (_drawedNumber == 0) _drawedNumber = 10;
            /*************** CONTESTANT1 STRUCT ****************/
            twentyOneContests[contestIndex].contestant1.isTurn = true;
            twentyOneContests[contestIndex].contestant2.isTurn = false;
            twentyOneContests[contestIndex]
                .contestant2
                .drawedNumbersSum += _drawedNumber;
        }
        /*************** STRUCT ***************/
        // do it to others
        twentyOneContests[contestIndex].durationTime += 30;
        /*************** EVENT ***************/
        emit ContestantDrawedACard(_rank, _drawedNumber);
        /*************** WINNER ***************/
        determineWinner(_rank);
    }
    function determineAcesFate(
        uint256 _rank,
        uint256 acesFate
    )
        public
        ifContestExist(_rank)
        isContestEnded(_rank)
        ifContestant(_rank)
        ifAceDrawed(_rank)
    {
        /*************** CONTEST INDEX ****************/
        uint256 contestIndex = getContestIndexFromContestRank[_rank];
        /*************** CONTESTANT1 QUERY ****************/
        if (
            msg.sender == twentyOneContests[contestIndex].contestant1.contestant
        ) {
            /*************** CONTESTANT1 REVERT ****************/
            require(
                twentyOneContests[contestIndex].contestant1.isAceDrawed == true,
                "Contestant1DidntDrawAce"
            );
            /*************** CONTESTANT1 ACE'S FATE ****************/
            if (acesFate == 11)
                twentyOneContests[contestIndex]
                    .contestant1
                    .drawedNumbersSum += 10;
            /*************** CONTESTANT1 STRUCT ****************/
            twentyOneContests[contestIndex].contestant1.isAceDrawed = false;
            twentyOneContests[contestIndex].contestant2.playTime += 30;
            twentyOneContests[contestIndex].contestant1.playTime = block
                .timestamp;
        }
        /*************** CONTESTANT2 QUERY ****************/
        else {
            /*************** CONTESTANT1 REVERT ****************/
            require(
                twentyOneContests[contestIndex].contestant2.isAceDrawed == true,
                "Contestant2DidntDrawAce"
            );
            /*************** CONTESTANT1 ACE'S FATE ****************/
            if (acesFate == 11)
                twentyOneContests[contestIndex]
                    .contestant2
                    .drawedNumbersSum += 10;
            /*************** CONTESTANT1 STRUCT ****************/
            twentyOneContests[contestIndex].contestant2.isAceDrawed = false;
        }
        determineWinner(_rank);
    }
    function finishDrawing(
        uint256 _rank
    )
        public
        ifContestExist(_rank)
        isContestEnded(_rank)
        ifContestant(_rank)
        isFinished(_rank)
        ifNotAceDrawed(_rank)
    {
        /*************** CONTEST INDEX ****************/
        uint256 contestIndex = getContestIndexFromContestRank[_rank];
        /*************** CONTESTANT1 QUERY ****************/
        if (
            msg.sender == twentyOneContests[contestIndex].contestant1.contestant
        ) {
            /*************** CONTESTANT1 REVERT ****************/
            require(
                twentyOneContests[contestIndex].contestant1.isTurn,
                "InvalidContestant1Turn"
            );
            /*************** CONTESTANT1 STRUCT ****************/
            twentyOneContests[contestIndex].contestant2.isTurn = true;
            twentyOneContests[contestIndex].contestant1.isTurn = false;
            twentyOneContests[contestIndex].contestant1.isFinished = true;
        }
        /*************** CONTESTANT2 QUERY ****************/
        else {
            /*************** CONTESTANT2 REVERT ****************/
            require(
                twentyOneContests[contestIndex].contestant2.isTurn,
                "InvalidContestant2Turn"
            );
            /*************** CONTESTANT2 STRUCT ****************/
            twentyOneContests[contestIndex].contestant1.isTurn = true;
            twentyOneContests[contestIndex].contestant2.isTurn = false;
            twentyOneContests[contestIndex].contestant2.isFinished = true;
        }
        /*************** EVENT ****************/
        emit ContestantFinishedDrawingCards(_rank, msg.sender);
        /*************** WINNER ****************/
        determineWinner(_rank);
    }
    function determineWinner(uint256 _rank) private returns (address winner) {
        /*************** CONTEST INDEX ***************/
        uint256 contestIndex = getContestIndexFromContestRank[_rank];
        /*************** VARIABLES ***************/
        /*************** QUERY WINNER ***************/
        if (twentyOneContests[contestIndex].contestant1.drawedNumbersSum > 21) {
            winner = twentyOneContests[contestIndex].contestant2.contestant;
            twentyOneContests[contestIndex].end = true;
            twentyOneContests[contestIndex].winner = winner;
            twentyOneContests[contestIndex].durationTime = 0;
            emit ContestWinner(_rank, winner);
            payable(winner).transfer(
                twentyOneContests[contestIndex].collectedPrice
            );
            return winner;
        } else if (
            twentyOneContests[contestIndex].contestant2.drawedNumbersSum > 21
        ) {
            winner = twentyOneContests[contestIndex].contestant1.contestant;
            twentyOneContests[contestIndex].end = true;
            twentyOneContests[contestIndex].winner = winner;
            twentyOneContests[contestIndex].durationTime = 0;
            emit ContestWinner(_rank, winner);
            payable(winner).transfer(
                twentyOneContests[contestIndex].collectedPrice
            );
            return winner;
        } else if (
            twentyOneContests[contestIndex].contestant1.drawedNumbersSum ==
            21 &&
            twentyOneContests[contestIndex].contestant2.drawedNumbersSum == 21
        ) {
            winner = twentyOneContests[contestIndex].creator;
            twentyOneContests[contestIndex].end = true;
            twentyOneContests[contestIndex].winner = winner;
            twentyOneContests[contestIndex].durationTime = 0;
            emit ContestWinner(_rank, winner);
            payable(winner).transfer(
                twentyOneContests[contestIndex].collectedPrice
            );
            return winner;
        } else if (
            twentyOneContests[contestIndex].contestant1.isFinished &&
            twentyOneContests[contestIndex].contestant2.isFinished
        ) {
            if (
                twentyOneContests[contestIndex].contestant1.drawedNumbersSum >
                twentyOneContests[contestIndex].contestant2.drawedNumbersSum
            ) {
                winner = twentyOneContests[contestIndex].contestant1.contestant;
                twentyOneContests[contestIndex].end = true;
                twentyOneContests[contestIndex].winner = winner;
                twentyOneContests[contestIndex].durationTime = 0;
                emit ContestWinner(_rank, winner);
                payable(winner).transfer(
                    twentyOneContests[contestIndex].collectedPrice
                );
                return winner;
            } else if (
                twentyOneContests[contestIndex].contestant2.drawedNumbersSum >
                twentyOneContests[contestIndex].contestant1.drawedNumbersSum
            ) {
                winner = twentyOneContests[contestIndex].contestant2.contestant;
                twentyOneContests[contestIndex].end = true;
                twentyOneContests[contestIndex].winner = winner;
                twentyOneContests[contestIndex].durationTime = 0;
                emit ContestWinner(_rank, winner);
                payable(winner).transfer(
                    twentyOneContests[contestIndex].collectedPrice
                );
                return winner;
            }
        }
    }
}
