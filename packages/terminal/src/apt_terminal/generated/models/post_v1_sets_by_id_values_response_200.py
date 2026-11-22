from __future__ import annotations

from collections.abc import Mapping
from typing import TYPE_CHECKING, Any, Literal, TypeVar, cast
from uuid import UUID

from attrs import define as _attrs_define
from attrs import field as _attrs_field

from ..types import UNSET, Unset

if TYPE_CHECKING:
    from ..models.set_value import SetValue


T = TypeVar("T", bound="PostV1SetsByIdValuesResponse200")


@_attrs_define
class PostV1SetsByIdValuesResponse200:
    """
    Attributes:
        id (UUID):
        slug (str):
        name (str):
        description (str):
        is_default (bool): Applies to a customer who holds no live grant; one per ecosystem.
        is_personal (bool): A one-customer exception, hidden from the list and from offers.
        personal_customer_id (None | UUID):
        contains (list[UUID]): The sets it directly contains.
        values (list[SetValue]): Its own values.
        object_ (Literal['value'] | Unset):
    """

    id: UUID
    slug: str
    name: str
    description: str
    is_default: bool
    is_personal: bool
    personal_customer_id: None | UUID
    contains: list[UUID]
    values: list[SetValue]
    object_: Literal["value"] | Unset = UNSET
    additional_properties: dict[str, Any] = _attrs_field(init=False, factory=dict)

    def to_dict(self) -> dict[str, Any]:
        id = str(self.id)

        slug = self.slug

        name = self.name

        description = self.description

        is_default = self.is_default

        is_personal = self.is_personal

        personal_customer_id: None | str
        if isinstance(self.personal_customer_id, UUID):
            personal_customer_id = str(self.personal_customer_id)
        else:
            personal_customer_id = self.personal_customer_id

        contains = []
        for contains_item_data in self.contains:
            contains_item = str(contains_item_data)
            contains.append(contains_item)

        values = []
        for values_item_data in self.values:
            values_item = values_item_data.to_dict()
            values.append(values_item)

        object_ = self.object_

        field_dict: dict[str, Any] = {}
        field_dict.update(self.additional_properties)
        field_dict.update(
            {
                "id": id,
                "slug": slug,
                "name": name,
                "description": description,
                "is_default": is_default,
                "is_personal": is_personal,
                "personal_customer_id": personal_customer_id,
                "contains": contains,
                "values": values,
            }
        )
        if object_ is not UNSET:
            field_dict["object"] = object_

        return field_dict

    @classmethod
    def from_dict(cls: type[T], src_dict: Mapping[str, Any]) -> T:
        from ..models.set_value import SetValue

        d = dict(src_dict)
        id = UUID(d.pop("id"))

        slug = d.pop("slug")

        name = d.pop("name")

        description = d.pop("description")

        is_default = d.pop("is_default")

        is_personal = d.pop("is_personal")

        def _parse_personal_customer_id(data: object) -> None | UUID:
            if data is None:
                return data
            try:
                if not isinstance(data, str):
                    raise TypeError()
                personal_customer_id_type_0 = UUID(data)

                return personal_customer_id_type_0
            except (TypeError, ValueError, AttributeError, KeyError):
                pass
            return cast(None | UUID, data)

        personal_customer_id = _parse_personal_customer_id(d.pop("personal_customer_id"))

        contains = []
        _contains = d.pop("contains")
        for contains_item_data in _contains:
            contains_item = UUID(contains_item_data)

            contains.append(contains_item)

        values = []
        _values = d.pop("values")
        for values_item_data in _values:
            values_item = SetValue.from_dict(values_item_data)

            values.append(values_item)

        object_ = cast(Literal["value"] | Unset, d.pop("object", UNSET))
        if object_ != "value" and not isinstance(object_, Unset):
            raise ValueError(f"object must match const 'value', got '{object_}'")

        post_v1_sets_by_id_values_response_200 = cls(
            id=id,
            slug=slug,
            name=name,
            description=description,
            is_default=is_default,
            is_personal=is_personal,
            personal_customer_id=personal_customer_id,
            contains=contains,
            values=values,
            object_=object_,
        )

        post_v1_sets_by_id_values_response_200.additional_properties = d
        return post_v1_sets_by_id_values_response_200

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
