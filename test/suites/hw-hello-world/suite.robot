*** Settings ***
Documentation    A simple test suite file for hardware.
Library          hw.hello.Library


*** Test Cases ***
HW Hello World
    Print    Hello world from hardware!
