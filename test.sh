#!/bin/bash

testFolder=$1
if [ -z "$1" ]; then
    echo "ERROR: expected 1 arguments, got 0"
    exit 1
fi

runTest() {
    local expected="$1"
    local actual="$2"
    
    if [ "$actual" = "$expected" ]; then
        echo "PASS"
    else
        echo "FAIL"
        echo "Expected: $expected"
        echo "Got: $actual"
    fi
}

testArchive() {
    local targetFolder="$1"
    local threshold=$2
    local number=$3

    archive_name="backup_$(date +"%Y-%m-%d_%H-%M-%S")"

    fileList=$(ls -ltr "$targetFolder" | grep '^-' | awk '{print $9}' | head -n $number)
    originalChecksums=$(generateChecksums $targetFolder "${fileList[@]}")

    ./backup.sh $targetFolder $threshold $number > /dev/null 2>&1

    if [ ! -d ~/backup/testFolder ]; then
        mkdir backup/testFolder
    fi
    
    tar -xzf ~/backup/$archive_name.gz -C backup/testFolder
    extractedChecksums=$(generateChecksums backup/testFolder/filesystem "${fileList[@]}")
    if [ "$originalChecksums" = "$extractedChecksums" ]; then
        echo "Files are identical."
    else
        echo "Files are different."
    fi
}

generateChecksums() {
    local target_folder="$1"
    local file_list=("${@}")

    for file in "${file_list[@]}"; do
        if [ -f "$target_folder/$file" ]; then
            sha256sum "$target_folder/$file"
        fi
    done | sort
}

spawn_files() {
    local num=$1
    for i in $(seq $num); do
        sudo dd if=/dev/urandom of=filesystem/$i bs=M count=100 status=progress > /dev/null 2>&1
    done
}





echo
echo "Тест 1: Недостаточно аргументов"
runTest "ERROR: expected 3 arguments, got less" "$(./backup.sh 2>&1)"
echo

echo "Тест 2: Несуществующая папка"
if [ ! -d ~/notExistDir ]; then
    runTest "ERROR: notExistDir does not exist." "$(./backup.sh notExistDir 80 2 2>&1)"
else
    echo "Ошибка тестирования: папка с именем notExistDir cуществует"
fi
echo

echo "Тест 3: Некорректное значение порога"
runTest "ERROR: entered percentage of threshold is not a number or it must be at least 0" "$(./backup.sh $testFolder abc 2 2>&1)"
echo

echo "Тест 4: Некорректное значение числа архивируемых файлов"
runTest "ERROR: entered number of archived files is not a number or it must be at least 1" "$(./backup.sh $testFolder 80 abc 2>&1)"
echo

echo "Тест 5: Папка не заполнена до порога"
sudo rm -rf $testFolder/*
runTest "Used $(df filesystem --output=pcent | tail -n 1 | tr -d ' %') %. It is less than 50 %, archiving is not required" "$(./backup.sh $testFolder 50 1 2>&1)"
echo

echo "Тест 6: сравнение файлов до архивации и после разахривации"
spawn_files 10
runTest "Files are identical." "$(testArchive filesystem 40 6)"
rm -rf backup/testFolder/*
rmdir backup/testFolder
