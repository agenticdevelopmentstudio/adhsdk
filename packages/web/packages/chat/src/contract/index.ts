// Cross-platform chat contract — TypeScript expression of the Swift
// protocols under apple/AgenticDeveloperHubSDK/SDK/Sources/. Keep both in lockstep.

export type { Participant } from './participants/Participant'
export type { ParticipantConversationState } from './participants/ParticipantConversationState'
export type { ParticipantKind } from './participants/ParticipantKind'

export type { AttachmentPresentation } from './media/AttachmentPresentation'
export type { AttachmentSource } from './media/AttachmentSource'
export type { MediaType } from './media/MediaType'

export type { Attachment } from './attachments/Attachment'
export type { InlineDocument } from './attachments/InlineDocument'
export type { InteractiveWidget } from './attachments/InteractiveWidget'
export type { WidgetResponse } from './attachments/WidgetResponse'

export type { Conversation } from './messages/Conversation'
export type { Message } from './messages/Message'
export type { MessageDeliveryStatus } from './messages/MessageDeliveryStatus'
export type { ReadReceipt } from './messages/ReadReceipt'

export type { Backend } from './backend/Backend'
export type { InboundEvent } from './backend/InboundEvent'

export type { ActiveCommand } from './commands/ActiveCommand'
export type { Command } from './commands/Command'
export type { CommandInvocation } from './commands/CommandInvocation'
export type { CommandInvoker } from './commands/CommandInvoker'
export type { CommandResult } from './commands/CommandResult'
export type { Skill } from './commands/Skill'
export type { Tool } from './commands/Tool'

export type { Permission } from './permissions/Permission'
export type { PermissionDecision } from './permissions/PermissionDecision'
export type { PermissionPrompt } from './permissions/PermissionPrompt'
export type { PermissionStore } from './permissions/PermissionStore'

export type { GatingHook } from './hooks/GatingHook'
export type { GatingPoint } from './hooks/GatingPoint'
export type { HookContext } from './hooks/HookContext'
export type { HookDecision } from './hooks/HookDecision'
export type { ObservingHook } from './hooks/ObservingHook'
export type { ObservingPoint } from './hooks/ObservingPoint'

export type { ChatConfig } from './configuration/ChatConfig'
export type { DisplayConfig } from './configuration/DisplayConfig'

export type { ActiveDraft } from './chat/ActiveDraft'
export type { ChatStateObserver } from './chat/ChatStateObserver'
export type { ChatUpdate } from './chat/ChatUpdate'
export type { ChatViewModel } from './chat/ChatViewModel'

export type { Orchestrator } from './orchestrator/Orchestrator'
