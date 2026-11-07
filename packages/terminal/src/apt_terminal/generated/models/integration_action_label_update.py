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


T = TypeVar("T", bound="IntegrationActionLabelUpdate")


@_attrs_define
class IntegrationActionLabelUpdate:
    """actionType=label_update — gmail: rename or restyle ONE label (children are not renamed); at least one field besides
    labelId is required

        Attributes:
            label_id (str):
            name (str | Unset):
            label_list_visibility (IntegrationGmailLabelListVisibility | Unset):
            message_list_visibility (IntegrationGmailMessageListVisibility | Unset):
            color (IntegrationGmailLabelColor | Unset):
    """

    label_id: str
    name: str | Unset = UNSET
    label_list_visibility: IntegrationGmailLabelListVisibility | Unset = UNSET
    message_list_visibility: IntegrationGmailMessageListVisibility | Unset = UNSET
    color: IntegrationGmailLabelColor | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        label_id = self.label_id

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
                "labelId": label_id,
            }
        )
        if name is not UNSET:
            field_dict["name"] = name
        if label_list_visibility is not UNSET:
            field_dict["labelListVisibility"] = label_list_visibility
        if message_list_visibility is not UNSET:
            field_dict["messageListVisibility"] = message_list_visibility
        if color is not UNSET:
            field_dict["color"] = color

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.integration_gmail_label_color import (
            IntegrationGmailLabelColor,
        )

        d = dict(src_dict)
        label_id = d.pop("labelId")

        name = d.pop("name", UNSET)

        _label_list_visibility = d.pop("labelListVisibility", UNSET)
        label_list_visibility: IntegrationGmailLabelListVisibility | Unset
        if isinstance(_label_list_visibility, Unset):
            label_list_visibility = UNSET
        else:
            label_list_visibility = IntegrationGmailLabelListVisibility(_label_list_visibility)

        _message_list_visibility = d.pop("messageListVisibility", UNSET)
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

        integration_action_label_update = cls(
            label_id=label_id,
            name=name,
            label_list_visibility=label_list_visibility,
            message_list_visibility=message_list_visibility,
            color=color,
        )

        integration_action_label_update.additional_properties = d
        return integration_action_label_update

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
