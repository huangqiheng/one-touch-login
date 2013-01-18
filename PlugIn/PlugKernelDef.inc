const
  SYSTEM_APP_CREATED      = 'Application created.';
  SYSTEM_APP_TERMINATED   = 'Application terminated.';
  SYSTEM_TASK_STARTED     = 'Task started.';
  SYSTEM_TASK_FINISHED    = 'Task finished.';
  SYSTEM_TASK_COPIED      = 'Task copied.';
  SYSTEM_TASK_DAEMON_BEGIN= 'Task daemon begin service.';
  SYSTEM_TASK_DAEMON_EXIT = 'Task daemon exit.';

  ERROR_TASK_INVALID     = 'Task invalid.';
  ERROR_TASK_INACTIVE    = 'Task inactive.';

Const
  INI_SECTION_SYSTEM = 'system';

  INI_KEY_TYPE = 'Type';
  INI_KEY_PLUGIN = 'Plugin';
  INI_KEY_PLUGBASE = 'PlugBase';
  INI_KEY_PLUGLIBS = 'PlugLibs';
  INI_KEY_PRIVACYFIELDS = 'PrivacyFields';
  INI_KEY_RIGHTLEVEL = 'DropMyRights';
  INI_KEY_INJECTMODE = 'InjectMode';   

  TYPE_NAME_AUTHLIB  = 'AuthLib';
  TYPE_NAME_PLUGIN   = 'Plugin';
  TYPE_NAME_PLUGLIB = 'PlugLib';
  TYPE_NAME_PLUGBASE = 'PlugBase';

  INI_SECTION_INPUT = 'input';
  INI_KEY_NAME = 'Name';
  INI_KEY_APPCMDLINE = 'AppCmdLine';


Const
  SAFER_LEVELID_FULLYTRUSTED = $40000;
  SAFER_LEVELID_NORMALUSER   = $20000;
  SAFER_LEVELID_CONSTRAINED  = $10000;

  PLUGIN_TYPE_AUTHLIB = 0;
  PLUGIN_TYPE_PLUGBASE = 1;
  PLUGIN_TYPE_PLUGLIB = 2;
  PLUGIN_TYPE_PLUGIN = 3;

  MESSAGE_TYPE_SYSTEM = 0;
  MESSAGE_TYPE_ERROR = 1;
  MESSAGE_TYPE_DEBUG = 2;
  MESSAGE_TYPE_LOG = 3;
  MESSAGE_TYPE_NOTICE = 4;
  MESSAGE_TYPE_APPDATA = 5;
  MESSAGE_TYPE_PROGRESS = 6;
  MESSAGE_TYPE_CONFIG = 7;
  MESSAGE_TYPE_KEYDATA = 8;

  INJECT_MODE_REMOTE_THREAD = 0;
  INJECT_MODE_DRIVER = 1;

  RUN_MODE_NORMAL = 0;
  RUN_MODE_DEBUG = 1;
  RUN_MODE_AUTOCONFIG = 2;

  PROGRESS_OPTYPE_CREATE = 0;
  PROGRESS_OPTYPE_REPORT = 1;
  PROGRESS_OPTYPE_DESTROY = 2;

Type
  TOnMessage = Procedure (Task: THandle; MsgType: Integer; MsgBuff: PChar; MsgSize: Integer); Stdcall;
  TOnProgress = Procedure (Task: THandle; OpType: Integer; Caption, Hint: PChar; Progress: Integer); Stdcall;
  TOnAppData = Procedure (Task: THandle; DataBuff: PChar; DataSize: Integer); Stdcall;
  TOnConfig = Procedure (Task: THandle; Key: PChar; Value: PChar); Stdcall;
  TOnKeyData = Procedure (Task: THandle; Key: PChar; Value: PChar); Stdcall;

