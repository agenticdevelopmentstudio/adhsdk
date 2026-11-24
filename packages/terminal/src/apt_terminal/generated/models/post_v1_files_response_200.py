from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.storage_attachment import StorageAttachment


T = TypeVar("T", bound="PostV1FilesResponse200")


@_attrs_define
class PostV1FilesResponse200:
    """
    Attributes:
        attachment (StorageAttachment):
        deduplicated (bool):
        object_ (Literal['file'] | Unset):
    """

    attachment: StorageAttachment
    deduplicated: bool
    object_: Literal["file"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        attachment = self.attachment.to_dict()

        deduplicated = self.deduplicated

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "attachment": attachment,
                "deduplicated": deduplicated,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.storage_attachment import StorageAttachment

        d = dict(src_dict)
        attachment = StorageAttachment.from_dict(d.pop("attachment"))

        deduplicated = d.pop("deduplicated")

        object_ = cast(Literal["file"] | Unset, d.pop("object", UNSET))
        if object_ != "file" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'file', got '{object_}'")

        post_v1_files_response_200 = cls(
            attachment=attachment,
            deduplicated=deduplicated,
            object_=object_,
        )

        post_v1_files_response_200.additional_properties = d
        return post_v1_files_response_200

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
