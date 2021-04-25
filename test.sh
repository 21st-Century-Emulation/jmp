docker build -q -t jmp --build-arg CONFIGURATION=Debug .
docker run --rm --name jmp -d -p 8080:8080 -e READ_MEMORY_API=http://localhost:8080/api/v1/readMemory jmp

sleep 5

RESULT=`curl -s --header "Content-Type: application/json" \
  --request POST \
  --data '{"id":"abcd", "opcode":202,"state":{"a":242,"b":0,"c":0,"d":5,"e":15,"h":10,"l":20,"flags":{"sign":true,"zero":true,"auxCarry":false,"parity":false,"carry":false},"programCounter":1,"stackPointer":2,"cycles":0,"interruptsEnabled":true}}' \
  http://localhost:8080/api/v1/execute\?operand2=5\&operand1=8`
EXPECTED='{"id":"abcd", "opcode":202,"state":{"a":242,"b":0,"c":0,"d":5,"e":15,"h":10,"l":20,"flags":{"sign":true,"zero":true,"auxCarry":false,"parity":false,"carry":false},"programCounter":1288,"stackPointer":2,"cycles":10,"interruptsEnabled":true}}'

docker kill jmp

DIFF=`diff <(jq -S . <<< "$RESULT") <(jq -S . <<< "$EXPECTED")`

if [ $? -eq 0 ]; then
    echo -e "\e[32mJMP Test Pass \e[0m"
    exit 0
else
    echo -e "\e[31mJMP Test Fail  \e[0m"
    echo "$RESULT"
    echo "$DIFF"
    exit -1
fi