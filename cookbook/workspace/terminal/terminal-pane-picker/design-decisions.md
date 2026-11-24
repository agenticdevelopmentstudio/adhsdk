
**Decision**: While the picker runs, every left click in the host window is caught and nothing else reacts to it.
**Rationale**: The source comment says nothing else in the window reacts to a click meant as a choice.
**Approved**: pending

**Decision**: Any connectable pane can be picked whether or not its terminal is running.
**Rationale**: Starting its terminal is the connection's business, not the picker's.
**Approved**: pending

**Decision**: After a pick the panel stays up with a confirmation and an OK button, and Return finishes it.
**Rationale**: The panel confirms the choice by naming the pane while the pane is outlined, so the user sees what was chosen before it closes.
**Approved**: pending

**Decision**: The panes are asked for again on every click.
**Rationale**: The answer follows the layout as panes are added or closed.
**Approved**: pending

**Decision**: The panel is floating, key only if needed and not hidden on deactivate.
**Rationale**: It must stay in view above the window while the user clicks a pane in that window, without taking the keyboard from it.
**Approved**: pending

**Decision**: The owner is told when the panel has closed, not when the pick is made.
**Rationale**: The source says to hold on to the picker while it runs and release it when it reports it finished.
**Approved**: pending

