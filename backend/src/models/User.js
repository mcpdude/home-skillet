const db = require('../config/database');
const bcrypt = require('bcryptjs');

class User {
  /**
   * Create a new user
   * @param {Object} userData - User data
   * @param {string} userData.email - User email
   * @param {string} userData.password - User password (will be hashed)
   * @param {string} userData.firstName - User first name
   * @param {string} userData.lastName - User last name
   * @returns {Object} Created user (without password)
   */
  static async create({ email, password, firstName, lastName }) {
    const hashedPassword = await bcrypt.hash(password, 12);
    
    const [user] = await db('users')
      .insert({
        email: email.toLowerCase().trim(),
        password: hashedPassword,
        first_name: firstName.trim(),
        last_name: lastName.trim(),
        created_at: new Date(),
        updated_at: new Date()
      })
      .returning(['id', 'email', 'first_name as firstName', 'last_name as lastName', 'created_at as createdAt']);

    return user;
  }

  /**
   * Find user by email
   * @param {string} email - User email
   * @returns {Object|null} User object or null if not found
   */
  static async findByEmail(email) {
    const user = await db('users')
      .select('id', 'email', 'password', 'first_name as firstName', 'last_name as lastName', 'created_at as createdAt')
      .where('email', email.toLowerCase().trim())
      .first();

    return user || null;
  }

  /**
   * Find user by ID
   * @param {number} id - User ID
   * @returns {Object|null} User object (without password) or null if not found
   */
  static async findById(id) {
    const user = await db('users')
      .select('id', 'email', 'first_name as firstName', 'last_name as lastName', 'created_at as createdAt')
      .where('id', id)
      .first();

    return user || null;
  }

  /**
   * Verify user password
   * @param {string} plainPassword - Plain text password
   * @param {string} hashedPassword - Hashed password from database
   * @returns {boolean} True if password matches
   */
  static async verifyPassword(plainPassword, hashedPassword) {
    return await bcrypt.compare(plainPassword, hashedPassword);
  }

  /**
   * Update user data
   * @param {number} id - User ID
   * @param {Object} updates - Fields to update
   * @returns {Object} Updated user (without password)
   */
  static async update(id, updates) {
    const updateData = { ...updates, updated_at: new Date() };
    
    // Convert camelCase to snake_case for database
    if (updateData.firstName) {
      updateData.first_name = updateData.firstName;
      delete updateData.firstName;
    }
    
    if (updateData.lastName) {
      updateData.last_name = updateData.lastName;
      delete updateData.lastName;
    }

    // Hash password if being updated
    if (updateData.password) {
      updateData.password = await bcrypt.hash(updateData.password, 12);
    }

    const [user] = await db('users')
      .where('id', id)
      .update(updateData)
      .returning(['id', 'email', 'first_name as firstName', 'last_name as lastName', 'updated_at as updatedAt']);

    return user;
  }

  /**
   * Delete user
   * @param {number} id - User ID
   * @returns {boolean} True if user was deleted
   */
  static async delete(id) {
    const deletedRows = await db('users').where('id', id).del();
    return deletedRows > 0;
  }

  /**
   * Check if email exists
   * @param {string} email - Email to check
   * @returns {boolean} True if email exists
   */
  static async emailExists(email) {
    const user = await db('users')
      .select('id')
      .where('email', email.toLowerCase().trim())
      .first();

    return !!user;
  }
}

module.exports = User;