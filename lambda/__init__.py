import os
import sys

sys.path.append(os.getenv('LAMBDA_TASK_ROOT'))

import fullcontact  # noqa

if __name__ == "__main__":
    fullcontact.handle_fanout(None, None)
