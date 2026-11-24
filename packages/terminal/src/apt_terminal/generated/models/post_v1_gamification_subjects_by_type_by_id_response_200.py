from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

T = TypeVar("T", bound="PostV1GamificationSubjectsByTypeByIdResponse200")


@_attrs_define
class PostV1GamificationSubjectsByTypeByIdResponse200:
    """
    Attributes:
        subject_type (str):
        subject_id (str):
        opted_out (bool):
        object_ (Literal['gamification.subject'] | Unset):
    """

    subject_type: str
    subject_id: str
    opted_out: bool
    object_: Literal["gamification.subject"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        subject_type = self.subject_type

        subject_id = self.subject_id

        opted_out = self.opted_out

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "subject_type": subject_type,
                "subject_id": subject_id,
                "opted_out": opted_out,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        subject_type = d.pop("subject_type")

        subject_id = d.pop("subject_id")

        opted_out = d.pop("opted_out")

        object_ = cast(Literal["gamification.subject"] | Unset, d.pop("object", UNSET))
        if object_ != "gamification.subject" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'gamification.subject', got '{object_}'")

        post_v1_gamification_subjects_by_type_by_id_response_200 = cls(
            subject_type=subject_type,
            subject_id=subject_id,
            opted_out=opted_out,
            object_=object_,
        )

        post_v1_gamification_subjects_by_type_by_id_response_200.additional_properties = d
        return post_v1_gamification_subjects_by_type_by_id_response_200

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
