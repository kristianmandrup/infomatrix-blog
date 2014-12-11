---
layout: post
title: Writing an EmberJS plugin for Webstorm
tags:
    - ember
    - cli
    - intellij
    - idea
    - plugin
category: ember
date: 11-07-2014
id: 13
---

A few weeks ago I started on the ambitious quest to write an IntelliJ IDEA plugin for EmberJS CLI, targeting the Webstorm IDE/Editor.
I used the AngularJS community plugin as my initial starting point. Much of that infrastructure looks ready to reuse and
 there are many similarities between the two frameworks with respect to basic language constructs, concepts etc.

I quickly reworked many of the Angular specific classes, renaming them for Ember and giving them some Ember flair.
Have yet to debug and test... I like to sketch out a rough skeleton and get an overview before going deeper.

<!--more-->

After making a post on twitter that I had started this plugin, @Jetbrains developer [Dennis Ushakov](https://twitter.com/en_Dal) contacted me and
 said he was very interested in my plugin project and was willing to help me out. Excellent :)

I thought I would start by writing a nice *New Project wizard* for *Ember CLI*.

### New project wizard

In order to create a New Project wizard for Ember, we simply have to extend `AbstractProjectWizard`.
When we call `super`, it will ask for the name of the project which we can later access via `project.getName()`.

To create the file structure of the project, we will execute the Ember CLI command `ember new <project-name>`.
CLI command execution will be handled by a separate class `CliCommandExecutor`.

We call `init` to initiate project creation. Here we setup a `WizardContext` which can contain multiple steps to step through
  as part of the creation (for later?). However currently we don't have any steps, so we just run `createNewProject(project)`
which executes the Ember CLI command with the project name.

```java
public class NewEmberProjectWizard extends AbstractProjectWizard {

    private final StepSequence mySequence = new StepSequence();
    private final CliCommandExecutor commandExecutor;

    public NewEmberProjectWizard(@Nullable Project project, @NotNull ModulesProvider modulesProvider, @Nullable String defaultPath) {
        super(IdeBundle.message("title.new.project"), project, defaultPath);
        commandExecutor = new CliCommandExecutor(getNewProjectFilePath());
        init(project, modulesProvider);
    }

    protected void init(@NotNull Project project, @NotNull ModulesProvider modulesProvider) {
        WizardContext myWizardContext = new WizardContext(project);
        myWizardContext.setNewWizard(true);
        if (myWizardContext.isCreatingNewProject()) {
            createNewProject(project);
        }
        super.init();
    }

    private void createNewProject(Project project) {
        commandExecutor.runCLICommand("ember new " + project.getName());
    }
```

The `CliCommandExecutor` runs an Ember CLI command via the `GeneralCommandLine` and implements `ProcessListener` so that
 we can listen to the process events such as when it terminates and act upon it.

```java
public class CliCommandExecutor implements ProcessListener {
    final String workDirectory;
    final Project project;
    List<CliTerminateHandler> handlers = new ArrayList<>();

    public CliCommandExecutor(Project project) {
        this.project = project;
        this.workDirectory = project.getProjectFilePath();
    }

    public CliCommandExecutor(Project, project, String workDirectory) {
        this.project = project;
        this.workDirectory = workDirectory;
    }

    public void runCLICommand(String command) {
        String[] arguments = command.split(" ");
        final GeneralCommandLine generalCommandLine = new GeneralCommandLine(arguments);
        generalCommandLine.setWorkDirectory(workDirectory);

        try {
            final OSProcessHandler handler = new OSProcessHandler(generalCommandLine);
            handler.addProcessListener(this);
            handler.startNotify();
            generalCommandLine.createProcess();
        } catch (Exception e) {
            handleError(e);
        }
    }

    @Nullable
    protected void handleError(Exception e) {
        writeError(e.getMessage());
    }

    @Override
    public void startNotified(ProcessEvent processEvent) {
    }

    @Override
    public void processTerminated(ProcessEvent processEvent) {
        processEvent.getExitCode() == 1 ? handleError(ProcessEvent pe) : handleSuccess(ProcessEvent pe);
    }

    protected handleError(ProcessEvent pe) {
      writeError("Process terminates with error");
      for (CliTerminateHandler handler : handlers) {
        handler.onError(this, pe);
      }
    }

    protected handleSuccess() {
      writeSuccess("Process terminates successfully");
      for (CliTerminateHandler handler : handlers) {
        handler.onSuccess(this, pe);
      }
    }

    public void addCliTerminateHandler(CliTerminateHandler handler) {
      handlers.add(handler);
    }

    private void writeSuccess(String msg) {
        System.out.println(msg);
    }

    private void writeError(String msg) {
        System.err.println(msg);
    }

    @Override
    public void processWillTerminate(ProcessEvent processEvent, boolean b) {

    }

    @Override
    public void onTextAvailable(ProcessEvent processEvent, Key key) {

    }
}
```

Note that for `processTerminated` we test the exit code to see if we got an error (= 1).
We can then look at the text via `processEvent.getText()` to see the cause of the error.
In this case, if the text matches `"command not found"` we assume that this is caused by `ember-cli` not being installed
so we can then run a CLI command to install it globally.
We register a `CliTerminateHandler` like this `commandExecutor.addCliTerminateHandler(handler)`;

The handler logic could look like this... which attempts to install ember-cli if command not found (not yet installed).

```java
public void onError(CliCommandExecutor ce, ProcessEvent processEvent) {
    String text = processEvent.getText();
    if (text.matches("command not found")) {
        runCLICommand("npm install -g ember-cli");
    }
    ...
```

We could also show a Modal Dialog to ask the user if he wants to install it or not.

```java
  if (text.matches("command not found") && prompt("Install", "Do you wish to install ember cli")) {
      runCLICommand("npm install -g ember-cli");
  }
  ...


private boolean prompt(final String title, final String question) {
    return Messages.showOkCancelDialog(project, question, title, Messages.getQuestionIcon()) == Messages.OK;
}
```


### New Ember class

When the Groovy plugin is enabled, You get to run `New -> Groovy class` from the menu.
Clicking this menu item shows a new dialog where you can:

- type the name of the class
- select the kind of Class to create, such as: `Class, Interface, Enum, Annotation, …`

The main logic for this is implemented in the `NewGroovyClassAction`

```java
public class NewGroovyClassAction extends JavaCreateTemplateInPackageAction<GrTypeDefinition> {

  public NewGroovyClassAction() {
    super(GroovyBundle.message("newclass.menu.action.text"), GroovyBundle.message("newclass.menu.action.description"),
          JetgroovyIcons.Groovy.Class, true);
  }
```

We can see that it looks up messages in the `GroovyBundle` for displaying labels, titles etc.
Also note the use of `JetgroovyIcons.Groovy.Class`. We need something similar for Ember.

If we look further down, we see the main Dialog method `buildDialog`.

`protected void buildDialog(Project project, PsiDirectory directory, CreateFileFromTemplateDialog.Builder builder)`

It takes the current project and directory and a `CreateFileFromTemplateDialog.Builder` instance.

The `doCreate` must be overridden to perform the actual creation of a `PsiFile` given the `PsiDirectory`
to place it in, a `className` and `templateName`. How we perform the actual file templating is
left up to us which is just fine.

```java
@Override
  protected final GrTypeDefinition doCreate(PsiDirectory dir, String className, String templateName) throws IncorrectOperationException {
    final String fileName = className + NewGroovyActionBase.GROOVY_EXTENSION;
    final PsiFile fromTemplate = GroovyTemplatesFactory.createFromTemplate(dir, className, fileName, templateName, true);
    if (fromTemplate instanceof GroovyFile) {
      CodeStyleManager.getInstance(fromTemplate.getManager()).reformat(fromTemplate);
      return ((GroovyFile)fromTemplate).getTypeDefinitions()[0];
    }
    final String description = fromTemplate.getFileType().getDescription();
    throw new IncorrectOperationException(GroovyBundle.message("groovy.file.extension.is.not.mapped.to.groovy.file.type", description));
  }
```

We can see here, that the main step involves using `GroovyTemplatesFactory.createFromTemplate`. Which returns a `PsiFile` for the file created.
We need a similar step that instead runs an ember cli command to generate a file from a blueprint. Then we need to wrap the generated
file as a `PsiFile` to be returned.

If we look into `GroovyTemplatesFactory.createFromTemplate` we find the following, which we can reuse for our scenario.

```java
final PsiFileFactory factory = PsiFileFactory.getInstance(project);
PsiFile file = factory.createFileFromText(fileName, GroovyFileType.GROOVY_FILE_TYPE, text);
```

Let's create a function named `EmberTemplatesFactory.createFromTemplate`. The Groovy example runs the Templating in-memory and
 generates the file text as a String. A `PsiFile` is then created from the fileName and text.

Since we are not running the templating in-memory but directly on the file system, we need to use a different approach.

Instead we can just have the IDE pick up the new file generated by running the ember cli `generate` command, using the built in file watching mechanism of the IDE.
Then we can skip the whole `createPsiFile` step and instead reuse `CliCommandExecutor` to run the process asynchronously...
Simpler and better!

The only catch here, is that the original logic assumes a blocking procedural flow. We need to somehow
register a callback for `processTerminated(ProcessEvent processEvent)` via some kind of `onSuccess` event.
We can do this via `executor.addSuccessHandler(this)` and then create a callback `public void onSuccess(CliCommandExecutor executor)`

```java
EmberTemplatesFactory {
  public void createFromTemplate(...) {
  String command = "ember g " + templateName + " " + className;
  try {
    CliCommandExecutor executor = new CliCommandExecutor(project).runCLICommand(command);
    executor.addSuccessHandler(this);
  } catch (Exception e) {
    handleError(e);
  }
}
```

Which calls onSuccess on the handler and proceeds... we just need somewhere, somehow to create the `PsiFile` ;)

```java
public void onSuccess(CliCommandExecutor executor) {
  PsiFile fromTemplate = executor.createPsiFile();

  if (fromTemplate instanceof GroovyFile) {
    CodeStyleManager.getInstance(fromTemplate.getManager()).reformat(fromTemplate);
    return ((GroovyFile)fromTemplate).getTypeDefinitions()[0];
  }
  final String description = fromTemplate.getFileType().getDescription();
  throw new IncorrectOperationException(GroovyBundle.message("groovy.file.extension.is.not.mapped.to.groovy.file.type", description));
}
```

Finally we also need to implement `isAvailable` which tells the IDE if the action should be made available at all given the current (project) context.
Here is the Groovy logic:

```java
@Override
  protected boolean isAvailable(DataContext dataContext) {
    return super.isAvailable(dataContext) && LibrariesUtil.hasGroovySdk(LangDataKeys.MODULE.getData(dataContext));
  }
```

Here testing for the *Groovy SDK*. We need a similar approach to detect if a project is an *Ember CLI* project,
such as testing for a `ember-cli` entry in the `package.json` file and the existence of a `Brocfile.js` perhaps?

This is my current ideas for some initial design and architecture. Please provide feedback with suggestions and improvements!

Cheers!

```java
public class NewGroovyClassAction extends JavaCreateTemplateInPackageAction<GrTypeDefinition> {

  public NewGroovyClassAction() {
    super(GroovyBundle.message("newclass.menu.action.text"), GroovyBundle.message("newclass.menu.action.description"),
          JetgroovyIcons.Groovy.Class, true);
  }

  @Override
  protected void buildDialog(Project project, PsiDirectory directory, CreateFileFromTemplateDialog.Builder builder) {
    builder
      .setTitle(GroovyBundle.message("newclass.dlg.title"))
      .addKind("Class", JetgroovyIcons.Groovy.Class, GroovyTemplates.GROOVY_CLASS)
      .addKind("Interface", JetgroovyIcons.Groovy.Interface, GroovyTemplates.GROOVY_INTERFACE);

    if (GroovyConfigUtils.getInstance().isVersionAtLeast(directory, GroovyConfigUtils.GROOVY2_3, true)) {
      builder.addKind("Trait", JetgroovyIcons.Groovy.Trait, GroovyTemplates.GROOVY_TRAIT);
    }

    builder
      .addKind("Enum", JetgroovyIcons.Groovy.Enum, GroovyTemplates.GROOVY_ENUM)
      .addKind("Annotation", JetgroovyIcons.Groovy.AnnotationType, GroovyTemplates.GROOVY_ANNOTATION);

    for (FileTemplate template : FileTemplateManager.getInstance().getAllTemplates()) {
      FileType fileType = FileTypeManagerEx.getInstanceEx().getFileTypeByExtension(template.getExtension());
      if (fileType.equals(GroovyFileType.GROOVY_FILE_TYPE) && JavaDirectoryService.getInstance().getPackage(directory) != null) {
        builder.addKind(template.getName(), JetgroovyIcons.Groovy.Class, template.getName());
      }
    }
  }
```