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
    When I run the "help" command with ""
    Then It should exit normally
    And The output should include "Usage: runssh \[global_options\] COMMAND \[options\] <path>"
    And The output should include "Available commands:"

  Scenario Outline: Subcommand help
    When I run the "help" command with "<subcommand>"
    Then It should exit normally
    And The output should include "<output>"

    Scenarios: Various subcommands help
      | subcommand | output                                           |
      | shell      | Connect to the specified host using ssh.         |
      | add        | Add a new host definition at the supplied <path> |
      | del        | Delete host definitions or `empty` groups        |
      | update     | Update host definition specified by <path>       |
      | print      | Print host configuration to the console.         |
      | import     | Imports a configuration.                         |
      | export     | Exports the configuration to a YAML file.        |
      | cpid       | Copy ssh public key to authorized_keys           |
