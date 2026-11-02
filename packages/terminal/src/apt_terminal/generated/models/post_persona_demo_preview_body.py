from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.post_persona_demo_preview_body_history_item import (
        PostPersonaDemoPreviewBodyHistoryItem,
    )


T = TypeVar("T", bound="PostPersonaDemoPreviewBody")


@_attrs_define
class PostPersonaDemoPreviewBody:
    """
    Attributes:
        source (str): The draft ink source, exactly as it sits in the editor
        sign_in_line (str | Unset): What the persona says to an anonymous visitor it cannot answer. Blank ⇒ the platform
            default.
        message (str | Unset): The visitor's message this turn. Omit it with an empty `history` to lint the script and
            see the opening block — the story plays its opening without consulting the message.
        history (list[PostPersonaDemoPreviewBodyHistoryItem] | Unset): The transcript BEFORE this message. The story is
            replayed over it.
        can_escalate (bool | Unset): Preview the SIGNED-IN visitor's demo, where an off-script message falls through to
            the real model (`text: null`). Default previews the anonymous one. Default: False.
    """

    source: str
    sign_in_line: str | Unset = UNSET
    message: str | Unset = UNSET
    history: list[PostPersonaDemoPreviewBodyHistoryItem] | Unset = UNSET
    can_escalate: bool | Unset = False
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        source = self.source

        sign_in_line = self.sign_in_line

        message = self.message

        history: list[dict[str, Any]] | Unset = UNSET
        if not isinstance(self.history, Unset):
            history = []
            for history_item_data in self.history:
                history_item = history_item_data.to_dict()
                history.append(history_item)

        can_escalate = self.can_escalate

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "source": source,
            }
        )
        if sign_in_line is not UNSET:
            field_dict["signInLine"] = sign_in_line
        if message is not UNSET:
            field_dict["message"] = message
        if history is not UNSET:
            field_dict["history"] = history
        if can_escalate is not UNSET:
            field_dict["canEscalate"] = can_escalate

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.post_persona_demo_preview_body_history_item import (
            PostPersonaDemoPreviewBodyHistoryItem,
        )

        d = dict(src_dict)
        source = d.pop("source")

        sign_in_line = d.pop("signInLine", UNSET)

        message = d.pop("message", UNSET)

        _history = d.pop("history", UNSET)
        history: list[PostPersonaDemoPreviewBodyHistoryItem] | Unset = UNSET
        if _history is not UNSET:
            history = []
            for history_item_data in _history:
                history_item = PostPersonaDemoPreviewBodyHistoryItem.from_dict(history_item_data)

                history.append(history_item)

        can_escalate = d.pop("canEscalate", UNSET)

        post_persona_demo_preview_body = cls(
            source=source,
            sign_in_line=sign_in_line,
            message=message,
            history=history,
            can_escalate=can_escalate,
        )

        post_persona_demo_preview_body.additional_properties = d
        return post_persona_demo_preview_body

    @property
    def additional_keys(self) -> list[str]:
        return list(self.additional_properties.keys())

    def __getitem__(self, key: str) -> Any:
        return self.additional_properties[key]

    def __setitem__(self, key: str, value: Any) -> None:
        self.additional_properties[key] = value

    def __delitem__(self, key: str) -> None:
        del self.additional_properties[key]

    def __contains__(self, key: str) -> bool:
        return key in self.additional_properties
