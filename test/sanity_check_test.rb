# frozen_string_literal: true

require 'test_helper'

class SanityCheckTest < GemTestCase
  test 'PostgreSQL and MySQL databases are properly isolated' do
    # Create a tag in PostgreSQL database
    pg_tag = Tag.create!(name: 'postgresql-only-tag')

    # Verify it exists in PostgreSQL
    assert Tag.exists?(name: 'postgresql-only-tag')
    assert_equal 1, Tag.where(name: 'postgresql-only-tag').count

    # Verify it does NOT exist in MySQL database
    assert_not MysqlTag.exists?(name: 'postgresql-only-tag')
    assert_equal 0, MysqlTag.where(name: 'postgresql-only-tag').count

    # Create a tag in MySQL database
    mysql_tag = MysqlTag.create!(name: 'mysql-only-tag')

    # Verify it exists in MySQL
    assert MysqlTag.exists?(name: 'mysql-only-tag')
    assert_equal 1, MysqlTag.where(name: 'mysql-only-tag').count

    # Verify it does NOT exist in PostgreSQL database
    assert_not Tag.exists?(name: 'mysql-only-tag')
    assert_equal 0, Tag.where(name: 'mysql-only-tag').count

    # Clean up
    pg_tag.destroy
    mysql_tag.destroy
  end

  test 'PostgreSQL models use PostgreSQL adapter' do
    assert_equal 'PostgreSQL', Tag.connection.adapter_name
    assert_equal 'PostgreSQL', TagAudit.connection.adapter_name
    assert_equal 'PostgreSQL', Label.connection.adapter_name
  end

  test 'MySQL models use MySQL adapter' do
    assert_equal 'Mysql2', MysqlTag.connection.adapter_name
    assert_equal 'Mysql2', MysqlTagAudit.connection.adapter_name
    assert_equal 'Mysql2', MysqlLabel.connection.adapter_name
  end

  test 'can write to both databases in same test' do
    # Create records in both databases
    pg_tag = Tag.create!(name: 'test-pg')
    mysql_tag = MysqlTag.create!(name: 'test-mysql')

    # Both should have IDs
    assert pg_tag.persisted?
    assert mysql_tag.persisted?

    # IDs should be independent (both could be 1 if tables are empty)
    assert_kind_of Integer, pg_tag.id
    assert_kind_of Integer, mysql_tag.id

    # Clean up
    pg_tag.destroy
    mysql_tag.destroy
  end
end
