from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1AudienceListsByIdRotateKeyResponse200")


@_attrs_define
class PostV1AudienceListsByIdRotateKeyResponse200:
    """
    Attributes:
        public_key (str): the list's NEW embed key. The old key stops working immediately — any page still embedding it
            must be updated.
        object_ (Literal['audience.list'] | Unset):
    """

    public_key: str
    object_: Literal["audience.list"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        public_key = self.public_key

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "public_key": public_key,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        public_key = d.pop("public_key")

        object_ = cast(Literal["audience.list"] | Unset, d.pop("object", UNSET))
        if object_ != "audience.list" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'audience.list', got '{object_}'")

        post_v1_audience_lists_by_id_rotate_key_response_200 = cls(
            public_key=public_key,
            object_=object_,
        )

        post_v1_audience_lists_by_id_rotate_key_response_200.additional_properties = d
        return post_v1_audience_lists_by_id_rotate_key_response_200

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
