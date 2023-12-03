/*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
 */

package main

import (
	"strconv"

	"github.com/hyperledger/fabric-chaincode-go/shim"
	pb "github.com/hyperledger/fabric-protos-go/peer"
)

const ERROR_SYSTEM = "{\"code\":300, \"reason\": \"system error: %s\"}"
const ERROR_WRONG_FORMAT = "{\"code\":301, \"reason\": \"command format is wrong\"}"
const ERROR_ACCOUNT_EXISTING = "{\"code\":302, \"reason\": \"account already exists\"}"
const ERROR_ACCOUNT_ABNORMAL = "{\"code\":303, \"reason\": \"abnormal account\"}"
const ERROR_MONEY_NOT_ENOUGH = "{\"code\":304, \"reason\": \"account's money is not enough\"}"

type SimpleChaincode struct {
}

func (t *SimpleChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {
	// nothing to do
	return shim.Success(nil)
}

func (t *SimpleChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {
	function, args := stub.GetFunctionAndParameters()

	if function == "open" {
		return t.Open(stub, args)
	}
	if function == "delete" {
		return t.Delete(stub, args)
	}
	if function == "query" {
		return t.Query(stub, args)
	}
	if function == "transfer" {
		return t.Transfer(stub, args)
	}
	if function == "raw2" {
		return t.Raw2(stub, args)
	}
	if function == "r2w2" {
		return t.R2w2(stub, args)
	}

	return shim.Error(ERROR_WRONG_FORMAT)
}

// open an account, should be [open account money]
func (t *SimpleChaincode) Open(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 2 {
		return shim.Error(ERROR_WRONG_FORMAT)
	}

	account := args[0]
	money, _ := stub.GetState(account)
	if money != nil {
		return shim.Error(ERROR_ACCOUNT_EXISTING)
	}

	stub.PutState(account, []byte(args[1]))

	return shim.Success(nil)
}

// delete an account, should be [delete account]
func (t *SimpleChaincode) Delete(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error(ERROR_WRONG_FORMAT)
	}

	stub.DelState(args[0])

	return shim.Success(nil)
}

// query current money of the account,should be [query accout]
func (t *SimpleChaincode) Query(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 1 {
		return shim.Error(ERROR_WRONG_FORMAT)
	}

	money, _ := stub.GetState(args[0])

	if money == nil {
		return shim.Error(ERROR_ACCOUNT_ABNORMAL)
	}

	return shim.Success(money)
}

// transfer money from account1 to account2, should be [transfer account1 account2 money]
func (t *SimpleChaincode) Transfer(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 3 {
		return shim.Error(ERROR_WRONG_FORMAT)
	}
	money, _ := strconv.Atoi(args[2])

	moneyBytes1, _ := stub.GetState(args[0])
	moneyBytes2, _ := stub.GetState(args[1])

	if moneyBytes1 == nil || moneyBytes2 == nil {
		return shim.Error(ERROR_ACCOUNT_ABNORMAL)
	}

	money1, _ := strconv.Atoi(string(moneyBytes1))
	money2, _ := strconv.Atoi(string(moneyBytes2))
	if money1 < money {
		return shim.Error(ERROR_MONEY_NOT_ENOUGH)
	}

	money1 -= money
	money2 += money

	stub.PutState(args[0], []byte(strconv.Itoa(money1)))
	stub.PutState(args[1], []byte(strconv.Itoa(money2)))

	return shim.Success(nil)
}

// read 2 accounts and write the second, should be [raw2 account1 account2]
func (t *SimpleChaincode) Raw2(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 2 {
		return shim.Error(ERROR_WRONG_FORMAT)
	}

	moneyBytes1, _ := stub.GetState(args[0])
	moneyBytes2, _ := stub.GetState(args[1])

	if moneyBytes1 == nil || moneyBytes2 == nil {
		return shim.Error(ERROR_ACCOUNT_ABNORMAL)
	}

	stub.PutState(args[1], moneyBytes1)

	return shim.Success(nil)
}

// read 2 accounts and write 2 accounts, should be [r2w2 account1 account2 account3 account4]
func (t *SimpleChaincode) R2w2(stub shim.ChaincodeStubInterface, args []string) pb.Response {
	if len(args) != 4 {
		return shim.Error(ERROR_WRONG_FORMAT)
	}

	moneyBytes1, _ := stub.GetState(args[0])
	moneyBytes2, _ := stub.GetState(args[1])
	moneyBytes3, _ := stub.GetState(args[3])
	moneyBytes4, _ := stub.GetState(args[4])

	if moneyBytes1 == nil || moneyBytes2 == nil || moneyBytes3 == nil || moneyBytes4 == nil {
		return shim.Error(ERROR_ACCOUNT_ABNORMAL)
	}

	stub.PutState(args[2], moneyBytes1)
	stub.PutState(args[3], moneyBytes2)

	return shim.Success(nil)
}

func main() {
	shim.Start(new(SimpleChaincode))
}
