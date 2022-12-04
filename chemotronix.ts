import { BigInt } from "@graphprotocol/graph-ts"
import {
  chemotronix,
  Approval,
  Transfer,
  balanceChecked,
  fundsWithdrawn,
  registration
} from "../generated/chemotronix/chemotronix"
import { Register, TransferCredit, Approve, Withdraw, balance } from "../generated/schema"
import "@graphprotocol/graph-ts";


export function handleApproval(event: Approval): void {
    let id = event.transaction.hash.toHex() + "-" + event.logIndex.toString();
    let newApproval = Approve.load(id);
    if (newApproval == null) {
      newApproval = new Approve(id);
      newApproval.owner = event.params.owner;
      newApproval.spender = event.params.spender;
      newApproval.amount = event.params.value;
      newApproval.save();
    }
}

export function handleTransfer(event: Transfer): void {
  let id = event.params.from.toHex();
  let newTransfer = TransferCredit.load(id);
  if(newTransfer == null){
    newTransfer = new TransferCredit(id);
    newTransfer.admin = event.params.from;
    newTransfer.companyAddress = event.params.to;
    newTransfer.tokenSupplied = event.params.value;
    newTransfer.save();
  }
}

export function handlebalanceChecked(event: balanceChecked): void {
  let id = event.transaction.hash.toHex();
  let newBalance = balance.load(id);
  if (newBalance == null) {
    newBalance = new balance(id);
    newBalance.balance = event.params.amount;
    newBalance.save();
  }
}

export function handlefundsWithdrawn(event: fundsWithdrawn): void {
  let id = event.transaction.hash.toHex();
  let newWithdrawal = Withdraw.load(id);
  if(newWithdrawal == null) {
    newWithdrawal = new Withdraw(id);
    newWithdrawal.admin = event.params.admin;
    newWithdrawal.amount = event.params.amount;
    newWithdrawal.save();
  }
}

export function handleregistration(event: registration): void {
  let id = event.transaction.hash.toHex() + "-" + event.logIndex.toString();;
  let newRegistration = Register.load(id);
  if(newRegistration == null) {
    newRegistration = new Register(id);
    //newRegistration.uniqueID = event.params.uniqueID;
    newRegistration.companyAddress = event.params.companyAddress;
    newRegistration.registrationTime = event.params.registrationTime;
    newRegistration.subStatus = "active";
  }
}
