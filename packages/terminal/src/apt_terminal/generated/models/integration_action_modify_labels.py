from __future__ import annotations

from collections.abc import Mapping
from typing import Any, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="IntegrationActionModifyLabels")


@_attrs_define
class IntegrationActionModifyLabels:
    """actionType=modify_labels — gmail: add and/or remove labels on 1 to 1000 messages; at least one of addLabelIds or
    removeLabelIds must be non-empty

        Attributes:
            message_ids (list[str]):
            add_label_ids (list[str] | Unset):
            remove_label_ids (list[str] | Unset):
    """

    message_ids: list[str]
    add_label_ids: list[str] | Unset = UNSET
    remove_label_ids: list[str] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        message_ids = self.message_ids

        add_label_ids: list[str] | Unset = UNSET
        if not isinstance(self.add_label_ids, Unset):
            add_label_ids = self.add_label_ids

        remove_label_ids: list[str] | Unset = UNSET
        if not isinstance(self.remove_label_ids, Unset):
            remove_label_ids = self.remove_label_ids

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "messageIds": message_ids,
            }
        )
        if add_label_ids is not UNSET:
            field_dict["addLabelIds"] = add_label_ids
        if remove_label_ids is not UNSET:
            field_dict["removeLabelIds"] = remove_label_ids

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        message_ids = cast(list[str], d.pop("messageIds"))

        add_label_ids = cast(list[str], d.pop("addLabelIds", UNSET))

        remove_label_ids = cast(list[str], d.pop("removeLabelIds", UNSET))

        integration_action_modify_labels = cls(
            message_ids=message_ids,
            add_label_ids=add_label_ids,
            remove_label_ids=remove_label_ids,
        )

        integration_action_modify_labels.additional_properties = d
        return integration_action_modify_labels

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
