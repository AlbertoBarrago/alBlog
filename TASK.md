# Phoenix Framework Study Tasks - Alblog Project

## 🎯 Overview
This document contains **7 essential tasks** to help you master the **Phoenix Framework** through hands-on development of a Alblog application. Each task builds upon the previous one, introducing core Phoenix concepts progressively.

## 📚 Learning Objectives
By completing these 7 tasks, you will understand:
- Phoenix project structure and conventions
- Ecto schemas and database operations
- LiveView for interactive web applications
- Component-based UI with HEEx templates
- Form handling and validation
- Basic CRUD operations in Phoenix

---

## 🚀 Task 1: Project Structure & Database Setup
**Estimated Time:** 45 minutes

**Objectives:**
- Understand Phoenix project architecture
- Set up your first database schema
- Learn Ecto migrations

**Steps:**
1. Explore the `lib/` directory structure and understand the separation between `alblog` (context) and `alblog_web` (web layer)
2. Design a `Product` schema with fields: `name` (string), `description` (text), `price` (decimal), `category` (string), `in_stock` (boolean)
3. Generate and run an Ecto migration: `mix phx.gen.schema Products.Product products name:string description:text price:decimal category:string in_stock:boolean`
4. Run `mix ecto.migrate` to create the table

**Success Criteria:** You have a working Product schema and database table

---

## 🏗️ Task 2: Your First LiveView
**Estimated Time:** 1 hour

**Objectives:**
- Create a LiveView module
- Learn the mount/3 callback
- Display data with HEEx templates

**Steps:**
1. Create `lib/alblog_web/live/product_live.ex` with a basic LiveView module
2. Implement the `mount/3` callback to load all products from the database
3. Create a template to display products in a clean table format
4. Add the route to `lib/alblog_web/router.ex`: `live "/products", ProductLive`
5. Style the table with Tailwind CSS classes

**Success Criteria:** You can visit `/products` and see a list of products (even if empty initially)

---

## 📝 Task 3: Create New Products
**Estimated Time:** 1.5 hours

**Objectives:**
- Build forms with Phoenix components
- Handle form submissions
- Implement validation and changesets

**Steps:**
1. Add a "New Product" section to your ProductLive template with a form
2. Use the imported `<.form>` component and `<.input>` components from `core_components.ex`
3. Create a changeset function in your Product schema for validation
4. Handle the "save" event in your LiveView to create new products
5. Add flash messages for success and error cases
6. Clear the form after successful submission

**Success Criteria:** You can create new products through the web interface with proper validation

---

## 👁️ Task 4: Display Product Details
**Estimated Time:** 45 minutes

**Objectives:**
- Create individual product views
- Learn LiveView navigation
- Practice conditional rendering

**Steps:**
1. Extend your ProductLive to handle showing individual products
2. Add a "View" link/button for each product in the table
3. Implement a detail view that shows all product information nicely formatted
4. Add a "Back to List" button
5. Handle the case when a product doesn't exist (show error message)

**Success Criteria:** You can click on any product to see its details and navigate back

---

## ✏️ Task 5: Edit Products Inline
**Estimated Time:** 2 hours

**Objectives:**
- Implement inline editing
- Manage LiveView state
- Handle form updates

**Steps:**
1. Add an "Edit" button to each product row in your table
2. Implement toggle functionality to switch between view and edit modes
3. Show form inputs inline when in edit mode
4. Handle "save" and "cancel" events
5. Update the product in the database and refresh the display
6. Add proper validation and error handling

**Success Criteria:** You can edit any product directly in the table row

---

## 🗑️ Task 6: Delete Products Safely
**Estimated Time:** 1 hour

**Objectives:**
- Implement delete functionality
- Add confirmation dialogs
- Handle error cases gracefully

**Steps:**
1. Add a "Delete" button to each product row
2. Implement a simple JavaScript confirmation dialog using `phx-confirm` attribute
3. Handle the delete event in your LiveView
4. Remove the product from the database and update the UI
5. Add proper error handling for cases where deletion fails
6. Show appropriate flash messages

**Success Criteria:** You can safely delete products with confirmation

---

## 🔍 Task 7: Add Search Functionality
**Estimated Time:** 1.5 hours

**Objectives:**
- Implement real-time search
- Learn about LiveView events
- Filter data dynamically

**Steps:**
1. Add a search input field at the top of your products page
2. Implement `phx-change` event to trigger search as user types
3. Filter products by name and description in your LiveView
4. Update the product list dynamically without page refresh
5. Add a "Clear" button to reset the search
6. Show "No products found" message when search returns no results
7. Consider adding a debounce to avoid excessive database queries

**Success Criteria:** You can search products in real-time and see filtered results instantly

---

## 🎉 Completion Checklist

After completing all 7 tasks, you should have:
- [ ] A fully functional CRUD application for products
- [ ] Real-time search and filtering
- [ ] Form validation and error handling
- [ ] Clean, responsive UI with Tailwind CSS
- [ ] Understanding of LiveView patterns and Phoenix conventions

## 🔄 Next Steps

Once you've mastered these 7 tasks, you'll be ready for more advanced Phoenix concepts like:
- Testing strategies
- Authentication and authorization
- Advanced LiveView features (streams, components)
- API development with Phoenix
- Deployment and production optimization

## 💡 Tips for Success

1. **Follow Phoenix conventions** - The framework works best when you follow its patterns
2. **Use the Phoenix generators** when helpful, but understand what they create
3. **Read error messages carefully** - Phoenix has excellent error reporting
4. **Experiment and break things** - The best way to learn is by doing
5. **Reference the official Phoenix guides** at https://hexdocs.pm/phoenix

Happy coding with Phoenix! 🚀