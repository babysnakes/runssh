Feature: Export bookmarks
  In order to view a list of all my bookmarks
  I want be able to export it to readable format.

  The export feature dumps the database into YAML file. This file
  could be edited and later imported into the database.
  
  Scenario: Missing required output file argument
    Given Existing database
    When I run the "export" command with:
      |option|argument|
      | |one two|
    Then I should get a "Error: option --output-file must be specified" error
  
  Scenario: Exporting bookmarks
    Given Bookmark "one two" exist with:
      |name|value|
      |host-name|ahost|
    When I export the database
    Then It should run successfully
    And The output file should contain ":host_name: ahost"
