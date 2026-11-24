from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, TypeVar

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.get_v1_projects_by_id_response_200_attachable import (
        GetV1ProjectsByIdResponse200Attachable,
    )
    from ..models.string_list import StringList


T = TypeVar("T", bound="GetV1ProjectsByIdResponse200")


@_attrs_define
class GetV1ProjectsByIdResponse200:
    """
    Attributes:
        attachable (GetV1ProjectsByIdResponse200Attachable | Unset):
        labels (StringList | Unset): A wrapper object `{ items: string[] }` (NOT a bare array). Returned by the public
            tag/category facet endpoints and the project label list.
    """

    attachable: GetV1ProjectsByIdResponse200Attachable | Unset = UNSET
    labels: StringList | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        attachable: dict[str, Any] | Unset = UNSET
        if not isinstance(self.attachable, Unset):
            attachable = self.attachable.to_dict()

        labels: dict[str, Any] | Unset = UNSET
        if not isinstance(self.labels, Unset):
            labels = self.labels.to_dict()

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update({})
        if attachable is not UNSET:
            field_dict["attachable"] = attachable
        if labels is not UNSET:
            field_dict["labels"] = labels

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.get_v1_projects_by_id_response_200_attachable import (
            GetV1ProjectsByIdResponse200Attachable,
        )
        from ..models.string_list import StringList

        d = dict(src_dict)
        _attachable = d.pop("attachable", UNSET)
        attachable: GetV1ProjectsByIdResponse200Attachable | Unset
        if isinstance(_attachable, Unset):
            attachable = UNSET
        else:
            attachable = GetV1ProjectsByIdResponse200Attachable.from_dict(_attachable)

        _labels = d.pop("labels", UNSET)
        labels: StringList | Unset
        if isinstance(_labels, Unset):
            labels = UNSET
        else:
            labels = StringList.from_dict(_labels)

        get_v1_projects_by_id_response_200 = cls(
            attachable=attachable,
            labels=labels,
        )

        get_v1_projects_by_id_response_200.additional_properties = d
        return get_v1_projects_by_id_response_200

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
