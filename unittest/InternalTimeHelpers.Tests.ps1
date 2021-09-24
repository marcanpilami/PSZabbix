BeforeAll {
    . $PSScriptRoot\..\src\InternalTimeHelpers.ps1
}


Describe "Time helpers" {
    Context "Simple conversions" {
        It "Converts DateTime to epoch" {
            $yesterday = Get-Date "Monday, May 14, 2018 9:00:00 PM"
            $epochTime = ConvertTo-EpochTime $yesterday
            $epochTime | should -Be 1526356800
        }

        It "Converts from epoch time to DateTime" {
            $yesterday = Get-Date "Monday, May 14, 2018 9:00:00 PM"
            $epochTime = 1526356800
            $yesterdayAgain = ConvertFrom-EpochTime $epochTime
            $yesterday | Should -Be $yesterdayAgain
        }
    }
}