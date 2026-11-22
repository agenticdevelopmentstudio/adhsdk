from __future__ import annotations

from collections.abc import Mapping
from typing import Any, Literal, TypeVar, cast

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..models.access_subject_kind import AccessSubjectKind
from ..types import UNSET, Unset

T = TypeVar("T", bound="GetV1AccessSubjectsResponse200DataItem")


@_attrs_define
class GetV1AccessSubjectsResponse200DataItem:
    """
    Attributes:
        kind (AccessSubjectKind):
        id (str):
        label (str): display name, else email, else slug
        email (None | str):
        slug (str):
        object_ (Literal['access.subject'] | Unset):
    """

    kind: AccessSubjectKind
    id: str
    label: str
    email: None | str
    slug: str
    object_: Literal["access.subject"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        kind = self.kind.value

        id = self.id

        label = self.label

        email: None | str
        email = self.email

        slug = self.slug

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "kind": kind,
                "id": id,
                "label": label,
                "email": email,
                "slug": slug,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        d = dict(src_dict)
        kind = AccessSubjectKind(d.pop("kind"))

        id = d.pop("id")

        label = d.pop("label")

        def _parse_email(data: object) -> None | str:
            if data is None:
                return data
            return cast(None | str, data)

        email = _parse_email(d.pop("email"))

        slug = d.pop("slug")

        object_ = cast(Literal["access.subject"] | Unset, d.pop("object", UNSET))
        if object_ != "access.subject" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'access.subject', got '{object_}'")

        get_v1_access_subjects_response_200_data_item = cls(
            kind=kind,
            id=id,
            label=label,
            email=email,
            slug=slug,
            object_=object_,
        )

        get_v1_access_subjects_response_200_data_item.additional_properties = d
        return get_v1_access_subjects_response_200_data_item

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
