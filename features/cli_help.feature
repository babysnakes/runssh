Feature: Cli help
  In order to know how to run the command
  As a user
  I want get assistance about the command.

  Scenario: Running without arguments
    When I run without arguments
    Then It should exit normally
    And The output should include "Usage: runssh \[global_options\] COMMAND \[options\] <path>"
    And The output should include "Available commands:"
  
  Scenario: Running with 'help' subcommand (and no further arguments)
    When I run the "help" command with:
      |option|argument|
    Then It should exit normally
    And The output should include "Usage: runssh \[global_options\] COMMAND \[options\] <path>"
    And The output should include "Available commands:"

