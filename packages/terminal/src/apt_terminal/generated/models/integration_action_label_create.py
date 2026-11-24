from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.integration_gmail_label_list_visibility import IntegrationGmailLabelListVisibility
from ..models.integration_gmail_message_list_visibility import IntegrationGmailMessageListVisibility
from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.integration_gmail_label_color import IntegrationGmailLabelColor


T = TypeVar("T", bound="IntegrationActionLabelCreate")


@_attrs_define
class IntegrationActionLabelCreate:
    """actionType=label_create — gmail: create a label. A `Parent/Child` name nests it under Parent

    Attributes:
        name (str):
        label_list_visibility (IntegrationGmailLabelListVisibility | Unset):
        message_list_visibility (IntegrationGmailMessageListVisibility | Unset):
        color (IntegrationGmailLabelColor | Unset):
    """

    name: str
    label_list_visibility: IntegrationGmailLabelListVisibility | Unset = UNSET
    message_list_visibility: IntegrationGmailMessageListVisibility | Unset = UNSET
    color: IntegrationGmailLabelColor | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        name = self.name

        label_list_visibility: str | Unset = UNSET
        if not isinstance(self.label_list_visibility, Unset):
            label_list_visibility = self.label_list_visibility.value

        message_list_visibility: str | Unset = UNSET
        if not isinstance(self.message_list_visibility, Unset):
            message_list_visibility = self.message_list_visibility.value

        color: dict[str, Any] | Unset = UNSET
        if not isinstance(self.color, Unset):
            color = self.color.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "name": name,
            }
        )
        if label_list_visibility is not UNSET:
            field_dict["label_list_visibility"] = label_list_visibility
        if message_list_visibility is not UNSET:
            field_dict["message_list_visibility"] = message_list_visibility
        if color is not UNSET:
            field_dict["color"] = color

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.integration_gmail_label_color import (
            IntegrationGmailLabelColor,
        )

        d = dict(src_dict)
        name = d.pop("name")

        _label_list_visibility = d.pop("label_list_visibility", UNSET)
        label_list_visibility: IntegrationGmailLabelListVisibility | Unset
        if isinstance(_label_list_visibility, Unset):
            label_list_visibility = UNSET
        else:
            label_list_visibility = IntegrationGmailLabelListVisibility(_label_list_visibility)

        _message_list_visibility = d.pop("message_list_visibility", UNSET)
        message_list_visibility: IntegrationGmailMessageListVisibility | Unset
        if isinstance(_message_list_visibility, Unset):
            message_list_visibility = UNSET
        else:
            message_list_visibility = IntegrationGmailMessageListVisibility(
                _message_list_visibility
            )

        _color = d.pop("color", UNSET)
        color: IntegrationGmailLabelColor | Unset
        if isinstance(_color, Unset):
            color = UNSET
        else:
            color = IntegrationGmailLabelColor.from_dict(_color)

        integration_action_label_create = cls(
            name=name,
            label_list_visibility=label_list_visibility,
            message_list_visibility=message_list_visibility,
            color=color,
        )

        integration_action_label_create.additional_properties = d
        return integration_action_label_create

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
