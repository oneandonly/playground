--
-- See https://twitter.com/#!/dibblego/status/130796120107532289
-- "Compute the average of an immutable single linked list (cons list) of integers. No variables."
--

import Control.Arrow
import Data.List (genericLength)

compute = sum &&& genericLength >>> uncurry (/)
