lapis = require "lapis"
csrf = require "lapis.csrf"
config = require("lapis.config").get!

bcrypt = require "bcrypt"

import respond_to from require "lapis.application"

Users = require "models.Users"

class extends lapis.Application
  @path: "/users"
  @name: "user_"

  [new: "/new"]: respond_to {
    GET: =>
      if @session.id
        @session.info = "You are logged into an account already."
        return redirect_to: @url_for "user_me"

      csrf_token = csrf.generate_token @

      @html ->
        form {
          action: @url_for "user_new"
          method: "POST"
          enctype: "multipart/form-data"
        }, ->
          p "Username: "
          input type: "text", name: "name"
          p "Email: "
          input type: "email", name: "email"
          p "Password: "
          input type: "password", name: "password"
          br!
          input type: "hidden", name: "csrf_token", value: csrf_token
          input type: "submit"

    POST: =>
      csrf.assert_token @
      -- TODO rewrite to be better
      if #@params.password < 8
        @session.info = "Your password must be at least 8 characters long."
        return redirect_to: @url_for "user_new"

      digest = bcrypt.digest @params.password, config.digest_rounds

      user, errMsg = Users\create {
        name: @params.name
        email: @params.email
        digest: digest
      }

      if user
        @session.id = user.id
        unless Users\find admin: true
          user\update { admin: true }
        return redirect_to: @url_for "index"

      else
        @session.info = "Error while creating user: #{errMsg}"
        return redirect_to: @url_for "user_new"
  }

  [me: "/me"]: =>
    unless @session.id
      @session.info = "You are not logged in."
      return redirect_to: @url_for "user_login"

    user = Users\find id: @session.id

    @html ->
      p "Username: #{user.name} (#{user.id})"
      p "Email Address: #{user.email}"
      p "Is admin? #{user.admin}"
      p -> a href: @url_for("user_edit"), "Edit"

  [edit: "/edit"]: respond_to {
    GET: =>
      unless @session.id
        @session.info = "You are not logged in."
        return redirect_to: @url_for "user_login"

      csrf_token = csrf.generate_token @
      user = Users\find id: @session.id

      @html ->
        form {
          action: @url_for "user_edit"
          method: "POST"
          enctype: "multipart/form-data"
        }, ->
          text "Change username? "
          input type: "text", name: "name", value: user.name
          br!
          input type: "hidden", name: "csrf_token", value: csrf_token
          input type: "submit"
        hr!

        form {
          action: @url_for "user_edit"
          method: "POST"
          enctype: "multipart/form-data"
        }, ->
          text "Change email address? "
          input type: "email", name: "email", value: user.email
          br!
          input type: "hidden", name: "csrf_token", value: csrf_token
          input type: "submit"
        hr!

        form {
          action: @url_for "user_edit"
          method: "POST"
          enctype: "multipart/form-data"
        }, ->
          p "Change password?"
          element "table", ->
            tr ->
              td "Old password:"
              td -> input type: "password", name: "oldpassword"
            tr ->
              td "New password:"
              td -> input type: "password", name: "password"
          input type: "hidden", name: "csrf_token", value: csrf_token
          input type: "submit"
        hr!

        form {
          action: @url_for "user_edit"
          method: "POST"
          enctype: "multipart/form-data"
          onsubmit: "return confirm('Are you sure you want to do this?');"
        }, ->
          text "Delete user? "
          input type: "checkbox", name: "delete"
          br!
          input type: "hidden", name: "csrf_token", value: csrf_token
          input type: "submit"

    POST: =>
      csrf.assert_token @
      user = Users\find id: @session.id

      if @params.name and @params.name\len! > 0
        user\update { name: @params.name }
        return redirect_to: @url_for "user_me"

      if @params.email and @params.email\len! > 0
        user\update { email: @params.email }
        return redirect_to: @url_for "user_me"

      elseif @params.password and @params.password\len! > 0
        if bcrypt.verify @params.oldpassword, user.digest
          digest = bcrypt.digest @params.password, config.digest_rounds

          user\update {
            digest: digest
          }
        else
          @session.info = "Incorrect password."
          return redirect_to: @url_for "user_edit"

      elseif @params.delete
        if user\delete!
          @session.id = nil
          @session.info = "Account deleted."
          return redirect_to: @url_for "index"
        else
          @session.info = "There was an error while deleting your account."
          return redirect_to: @url_for "index"

      return redirect_to: @url_for "user_edit"
  }

  [admin: "/admin"]: respond_to {
    GET: =>
      unless @session.id
        return redirect_to: @url_for "index"

      csrf_token = csrf.generate_token @
      user = Users\find id: @session.id

      unless user.admin
        @session.info = "You are not an administrator."
        return redirect_to: @url_for "user_me"

      @user_editing = Users\find id: @session.id

      render: true

    POST: =>
      unless @session.id
        return redirect_to: @url_for "index"

      csrf.assert_token @
      user = Users\find id: @session.id

      unless user.admin
        @session.info = "You are not an administrator."
        return redirect_to: @url_for "user_me"

      if @params.change_name and @params.change_name\len! > 0
        @user_editing = Users\find name: @params.change_name
      elseif @params.change_id
        @user_editing = Users\find id: @params.change_id
      else
        @user_editing = Users\find id: @params.id

      if @params.name and @params.name\len! > 0
        @user_editing\update {
          name: @params.name
        }
      elseif @params.email and @params.email\len! > 0
        @user_editing\update {
          email: @params.email
        }
      elseif @params.password and @params.password\len! > 0
        digest = bcrypt.digest @params.password, config.digest_rounds
        @user_editing\update {
          digest: digest
        }
      elseif @params.admin ~= nil
        @user_editing\update {
          admin: @params.admin
        }
      elseif @params.delete
        if @user_editing\delete!
          @user_editing = user
        else
          @session.info = "Error deleting that account."
          return redirect_to: @url_for "user_admin"

      --if not @user_editing
      --  @user_editing = user

      return render: true
  }

  [list: "/list"]: =>
    unless @session.id and (Users\find id: @session.id).admin
      @session.info = "You are not an administrator."
      return redirect_to: @url_for "index"

    users = Users\select "WHERE true ORDER BY name ASC"

    @html ->
      p "#{Users\count!} users."
      ul ->
        for user in *users
          li "#{user.name} (#{user.id}) #{user.email}"

  [login: "/login"]: respond_to {
    GET: =>
      if @session.id
        @session.info = "You are already logged in."
        return redirect_to: @url_for "user_me"

      csrf_token = csrf.generate_token @

      @html ->
        form {
          action: @url_for "user_login"
          method: "POST"
          enctype: "multipart/form-data"
        }, ->
          text "Username: "
          input type: "text", name: "name"
          br!
          text "Password: "
          input type: "password", name: "password"
          br!
          input type: "hidden", name: "csrf_token", value: csrf_token
          input type: "submit"

    POST: =>
      csrf.assert_token @
      if user = Users\find name: @params.name
        if bcrypt.verify @params.password, user.digest
          @session.id = user.id
          @session.info = "Logged in."
          if @session.redirect
            return redirect_to: @session.redirect
          else
            return redirect_to: @url_for "user_me"

      @session.info = "Invalid username or password."
      return redirect_to: @url_for "user_login"
  }

  [logout: "/logout"]: =>
    @session.id = nil
    return redirect_to: @url_for "index"
