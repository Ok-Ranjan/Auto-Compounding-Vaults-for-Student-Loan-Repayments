// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StudentLoanVault {
    struct StudentLoan {
        uint256 principal;
        uint256 accruedInterest;
        uint256 lastUpdated;
    }

    mapping(address => StudentLoan) public loans;
    uint256 public interestRate; // Annual interest rate in basis points (e.g., 500 = 5%)

    event LoanUpdated(address indexed student, uint256 newPrincipal, uint256 newAccruedInterest);

    constructor(uint256 _interestRate) {
        interestRate = _interestRate;
    }

    function addLoan(address _student, uint256 _principal) external {
        require(loans[_student].principal == 0, "Loan already exists");
        loans[_student] = StudentLoan({
            principal: _principal,
            accruedInterest: 0,
            lastUpdated: block.timestamp
        });
        emit LoanUpdated(_student, _principal, 0);
    }

    function updateAccruedInterest(address _student) public {
        StudentLoan storage loan = loans[_student];
        require(loan.principal > 0, "No loan found");
        
        uint256 timeElapsed = block.timestamp - loan.lastUpdated;
        uint256 interest = (loan.principal * interestRate * timeElapsed) / (365 days * 10000);

        loan.accruedInterest += interest;
        loan.lastUpdated = block.timestamp;
        emit LoanUpdated(_student, loan.principal, loan.accruedInterest);
    }

    function repayLoan(address _student, uint256 _amount) external {
        updateAccruedInterest(_student);

        StudentLoan storage loan = loans[_student];
        require(loan.principal > 0, "No loan found");

        uint256 totalDebt = loan.principal + loan.accruedInterest;
        require(_amount <= totalDebt, "Repayment exceeds total debt");

        if (_amount <= loan.accruedInterest) {
            loan.accruedInterest -= _amount;
        } else {
            uint256 remaining = _amount - loan.accruedInterest;
            loan.accruedInterest = 0;
            loan.principal -= remaining;
        }

        emit LoanUpdated(_student, loan.principal, loan.accruedInterest);
    }

    function getLoanDetails(address _student) external view returns (uint256, uint256, uint256) {
        StudentLoan storage loan = loans[_student];
        return (loan.principal, loan.accruedInterest, loan.lastUpdated);
    }
}
