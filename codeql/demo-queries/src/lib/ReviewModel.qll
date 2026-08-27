import csharp

class PublicAsyncVoidMethod extends Method {
  PublicAsyncVoidMethod() {
    this.isPublic() and
    this.getName().matches("%Async") and
    this.getReturnType() instanceof VoidType
  }
}

