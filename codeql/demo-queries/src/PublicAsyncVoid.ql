/**
 * @name Public async API returns void
 * @description Public methods whose names end in Async should return Task or Task<T> so callers can observe completion and exceptions.
 * @kind problem
 * @problem.severity warning
 * @precision high
 * @id codeql-demo/public-async-void
 * @tags reliability
 *       maintainability
 */

import csharp
import lib.ReviewModel

from PublicAsyncVoidMethod method
select method, "Return Task or Task<T> instead of void from this async API."

